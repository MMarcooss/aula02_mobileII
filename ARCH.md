# ARCH.md — Documentação Arquitetural

## Projeto: Todos App — Refatoração Feature-First

---

## 1. Estrutura de Pastas

```
lib/
├── main.dart                          ← Composição root (DI manual)
│
├── core/
│   ├── app_root.dart                  ← Widget raiz do MaterialApp
│   └── errors/
│       └── app_errors.dart            ← Classe AppError (exceção tipada)
│
└── features/
    └── todos/
        ├── data/
        │   ├── datasources/
        │   │   ├── todo_local_datasource.dart   ← SharedPreferences
        │   │   └── todo_remote_datasource.dart  ← HTTP (jsonplaceholder)
        │   ├── models/
        │   │   └── todo_model.dart              ← DTO com fromJson/toJson
        │   └── repositories/
        │       └── todo_repository_impl.dart    ← Implementação concreta
        │
        ├── domain/
        │   ├── entities/
        │   │   └── todo.dart                    ← Entidade pura de domínio
        │   └── repositories/
        │       └── todo_repository.dart         ← Contrato (abstract class)
        │
        └── presentation/
            ├── pages/
            │   └── todos_page.dart              ← Tela principal
            ├── viewmodels/
            │   └── todo_viewmodel.dart          ← Estado + lógica de UI
            └── widgets/
                └── add_todo_dialog.dart         ← Dialog reutilizável
```

---

## 2. Diagrama do Fluxo de Dependências

```
┌────────────────────────────────────────────────────────────────┐
│                        PRESENTATION                            │
│                                                                │
│   TodosPage / AddTodoDialog                                    │
│         │  context.read<TodoViewModel>()                       │
│         ▼                                                       │
│   TodoViewModel  (ChangeNotifier)                              │
│         │  usa apenas: TodoRepository (abstrato)               │
└─────────┼──────────────────────────────────────────────────────┘
          │
          │  interface (abstract class)
          ▼
┌────────────────────────────────────────────────────────────────┐
│                          DOMAIN                                │
│                                                                │
│   TodoRepository  ◄──── TodoFetchResult, Todo                 │
└─────────┬──────────────────────────────────────────────────────┘
          │
          │  implements
          ▼
┌────────────────────────────────────────────────────────────────┐
│                           DATA                                 │
│                                                                │
│   TodoRepositoryImpl                                           │
│      │ centraliza: remoto ou local?                            │
│      ├──► TodoRemoteDataSource  →  HTTP (http.Client)         │
│      └──► TodoLocalDataSource   →  SharedPreferences          │
│                                                                │
│   TodoModel  (DTO: fromJson / toJson)                         │
└────────────────────────────────────────────────────────────────┘

                    ▲ toda injeção é montada em:
┌────────────────────────────────────────────────────────────────┐
│  main.dart  (Composição Root)                                  │
│                                                                │
│   1. TodoRemoteDataSource()                                    │
│   2. TodoLocalDataSource()                                     │
│   3. TodoRepositoryImpl(remote, local)                         │
│   4. TodoViewModel(repo: repository)  ──► Provider            │
└────────────────────────────────────────────────────────────────┘
```

---

## 3. Justificativa da Estrutura

### Por que Feature-First?

A organização **feature-first** agrupa todos os arquivos relacionados a uma
funcionalidade (data, domain e presentation) dentro de uma pasta única
(`features/todos/`). Isso traz benefícios claros:

- **Escalabilidade**: adicionar uma nova feature (ex.: `auth/`, `profile/`)
  não polui pastas globais e não exige reorganização de toda a estrutura.
- **Coesão**: tudo que pertence a "todos" está junto — fácil de localizar,
  mover ou deletar a feature inteira.
- **Isolamento**: cada feature pode evoluir de forma independente.

### Por que `core/`?

A pasta `core/` concentra o que é **transversal** a todas as features:
tratamento de erros (`AppError`), o widget raiz (`AppRoot`) e, futuramente,
serviços globais como logging e navegação. Itens em `core/` não pertencem a
nenhuma feature específica.

---

## 4. Decisões de Responsabilidade

### `main.dart` — Composição Root e Injeção de Dependência

Único lugar onde as implementações concretas são instanciadas e conectadas.
A ordem de montagem é: DataSources → Repository → ViewModel. Nenhuma outra
camada precisa saber "de onde vem" a dependência; elas recebem as abstrações
prontas.

### `TodoViewModel` — Estado e Lógica de UI

Conhece **apenas** a abstração `TodoRepository`, nunca a implementação.
Não importa `http`, `SharedPreferences`, `BuildContext` nem nenhum Widget.
Gerencia estado reativo (`isLoading`, `errorMessage`, `items`) via
`ChangeNotifier` e faz rollback otimista em caso de falha no `toggleCompleted`.
O repositório é `required` no construtor, tornando a dependência explícita.

### `TodoRepository` (abstract class) — Contrato do Domínio

Define o contrato que o ViewModel consome. Expõe tipos do domínio (`Todo`,
`TodoFetchResult`) — nunca DTOs ou respostas HTTP. Permite trocar a
implementação (mock para testes, cache local, etc.) sem tocar em nenhuma
linha da UI.

### `TodoRepositoryImpl` — Decisor Remoto/Local

Centraliza a estratégia: buscar dados remotos e persistir o `lastSync`
localmente. Recebe `TodoRemoteDataSource` e `TodoLocalDataSource` por
injeção de dependência (nunca os instancia internamente). Converte
`TodoModel` (DTO) para `Todo` (entidade de domínio) antes de retornar.
Captura exceções e relança como `AppError` tipado.

### `TodoRemoteDataSource` — Acesso HTTP

Toda chamada `http.Client` fica **exclusivamente** aqui. Retorna `TodoModel`
(não `Todo`) — é responsabilidade da camada data trabalhar com DTOs.
A UI e o ViewModel jamais fazem chamadas HTTP diretamente.

### `TodoLocalDataSource` — Acesso SharedPreferences

Todo acesso a `SharedPreferences` fica **exclusivamente** aqui. A UI e o
ViewModel nunca chamam `SharedPreferences` diretamente.

### Onde ficou a validação?

A validação mínima de título vazio fica no **ViewModel** (`addTodo`), pois é
uma regra de comportamento da UI. Validações de regra de negócio mais
complexas ficariam nos **use cases** do domain (não necessários neste
projeto didático).

### Onde ficou o parsing JSON?

No `TodoModel.fromJson()`, dentro da camada **data/models**. O domínio
(entidade `Todo`) nunca vê JSON — ele só conhece tipos Dart puros.

### Como os erros são tratados?

Os DataSources lançam `Exception` genérica em caso de HTTP de erro.
O `TodoRepositoryImpl` captura e relança como `AppError` (tipado, de `core/`).
O ViewModel captura `AppError` e escreve `errorMessage` como String de estado,
que a UI exibe sem precisar saber nada sobre a origem do erro.

---

## 5. Regras Cumpridas

| Regra | Status | Evidência |
|---|---|---|
| UI não chama HTTP nem SharedPreferences | ✅ | `TodosPage` e `AddTodoDialog` só interagem com `TodoViewModel` |
| ViewModel não conhece Widgets/BuildContext | ✅ | `TodoViewModel` importa apenas `flutter/foundation.dart` e interfaces do domínio |
| Repository centraliza remoto/local | ✅ | `TodoRepositoryImpl.fetchTodos()` decide a estratégia de dados |
| Lógica interna das classes não alterada | ✅ | Comportamento idêntico ao original |
| Estrutura feature-first | ✅ | `lib/features/todos/{data,domain,presentation}/` |

---

## 6. Problemas Corrigidos na Refatoração

| Problema original | Correção aplicada |
|---|---|
| `app_root.dart` estava em `lib/ui/` (pasta errada) | Movido para `lib/core/` |
| `main.dart` importava `ui/app_root.dart` (caminho quebrado) | Import corrigido para `core/app_root.dart` |
| `TodoViewModel` importava e instanciava `TodoRepositoryImpl` diretamente | Dependência concreta removida; repositório recebido via construtor `required` |
| `TodoRepositoryImpl` hardcodava `= TodoRemoteDataSource()` nos campos | DataSources injetados via construtor com parâmetros `required` |
| `AppError` declarado mas nunca utilizado | Agora usado em `TodoRepositoryImpl` para relançar erros de forma tipada |