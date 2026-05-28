# API Trello Clone - Endpoints Completos

## Autenticación
```
POST /api/auth/login
POST /api/auth/refresh
POST /api/auth/logout
GET  /api/auth/me
GET  /api/auth/mfa/setup
POST /api/auth/mfa/verify
POST /api/auth/mfa/reconfigure
```

## Boards
```
GET    /api/boards
POST   /api/boards
GET    /api/boards/:id
PUT    /api/boards/:id
DELETE /api/boards/:id
```

## Lists
```
GET       /api/boards/:boardId/lists
POST      /api/boards/:boardId/lists
PATCH     /api/boards/:boardId/lists/reorder
PUT       /api/lists/:id
DELETE    /api/lists/:id
```

## Cards
```
GET         /api/lists/:listId/cards
POST        /api/lists/:listId/cards
PATCH       /api/lists/:listId/cards/reorder
PATCH       /api/cards/:id/move
GET         /api/cards/:id
PUT         /api/cards/:id
DELETE      /api/cards/:id
GET         /api/lists (standalone)
POST        /api/cards (standalone)
```

## Custom Fields
```
GET            /api/boards/:boardId/custom-fields
POST           /api/boards/:boardId/custom-fields
PUT            /api/custom-fields/:id
DELETE         /api/custom-fields/:id
```

## Card Field Values
```
GET  /api/cards/:cardId/field-values
POST /api/cards/:cardId/field-values
PUT  /api/cards/:cardId/field-values/:fieldId
DELETE /api/cards/:cardId/field-values/:fieldId
```

## Health Check
```
GET /health
```

## Swagger UI
```
GET /api-docs
```