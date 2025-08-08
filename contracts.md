# Contratos de API - App de Anotações

## 1. API Endpoints

### GET /api/notes
- **Descrição**: Buscar todas as anotações
- **Response**: 200 OK
```json
[
  {
    "id": "string",
    "title": "string",
    "content": "string", 
    "createdAt": "ISO date string",
    "updatedAt": "ISO date string"
  }
]
```

### POST /api/notes
- **Descrição**: Criar nova anotação
- **Request Body**:
```json
{
  "title": "string",
  "content": "string"
}
```
- **Response**: 201 Created
```json
{
  "id": "string",
  "title": "string", 
  "content": "string",
  "createdAt": "ISO date string",
  "updatedAt": "ISO date string"
}
```

### PUT /api/notes/{id}
- **Descrição**: Atualizar anotação existente
- **Request Body**:
```json
{
  "title": "string",
  "content": "string"
}
```
- **Response**: 200 OK (mesmo formato do POST)

### DELETE /api/notes/{id}
- **Descrição**: Excluir anotação
- **Response**: 200 OK
```json
{
  "message": "Anotação excluída com sucesso"
}
```

## 2. Dados Mock Substituídos

**Arquivo**: `/app/frontend/src/data/mock.js`
- **Substituir por**: Chamadas reais para os endpoints da API
- **Dados atuais**: 5 anotações de exemplo serão movidas para o banco MongoDB

## 3. Backend Implementation

### MongoDB Model
```python
class Note(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    title: str
    content: str
    createdAt: datetime = Field(default_factory=datetime.utcnow)
    updatedAt: datetime = Field(default_factory=datetime.utcnow)

class NoteCreate(BaseModel):
    title: str
    content: str

class NoteUpdate(BaseModel):
    title: str
    content: str
```

### Collection
- **Nome**: `notes`
- **Database**: MongoDB configurado via MONGO_URL

## 4. Frontend Integration Changes

### Arquivos a modificar:
1. **NotesPage.js**: Substituir `mockNotes` por chamadas de API
2. **Remover**: `/app/frontend/src/data/mock.js` 
3. **Adicionar**: Service functions para API calls

### API Service Functions:
```javascript
// services/notesApi.js
const API = `${process.env.REACT_APP_BACKEND_URL}/api`;

export const notesApi = {
  getAllNotes: () => axios.get(`${API}/notes`),
  createNote: (data) => axios.post(`${API}/notes`, data),
  updateNote: (id, data) => axios.put(`${API}/notes/${id}`, data),
  deleteNote: (id) => axios.delete(`${API}/notes/${id}`)
};
```

## 5. Error Handling
- **Conexão**: Toast com erro de conexão
- **Validação**: Validação no backend e frontend
- **Loading**: Estados de loading durante API calls

## 6. Migration Strategy
1. Implementar endpoints backend
2. Adicionar dados iniciais ao MongoDB
3. Substituir mock por API calls no frontend
4. Testar CRUD completo
5. Verificar persistência após restart do app