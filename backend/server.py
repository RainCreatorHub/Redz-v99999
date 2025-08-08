from fastapi import FastAPI, APIRouter, HTTPException
from dotenv import load_dotenv
from starlette.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
import os
import logging
from pathlib import Path
from pydantic import BaseModel, Field
from typing import List
import uuid
from datetime import datetime

ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

# MongoDB connection
mongo_url = os.environ['MONGO_URL']
client = AsyncIOMotorClient(mongo_url)
db = client[os.environ['DB_NAME']]

# Create the main app without a prefix
app = FastAPI()

# Create a router with the /api prefix
api_router = APIRouter(prefix="/api")

# Define Models
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

class StatusCheck(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    client_name: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)

class StatusCheckCreate(BaseModel):
    client_name: str

# Notes endpoints
@api_router.get("/notes", response_model=List[Note])
async def get_all_notes():
    """Buscar todas as anotações"""
    try:
        notes = await db.notes.find().sort("createdAt", -1).to_list(1000)
        return [Note(**note) for note in notes]
    except Exception as e:
        logger.error(f"Erro ao buscar anotações: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@api_router.post("/notes", response_model=Note)
async def create_note(note_data: NoteCreate):
    """Criar nova anotação"""
    try:
        note = Note(**note_data.dict())
        note_dict = note.dict()
        
        # Convert datetime to ISO string for MongoDB
        note_dict['createdAt'] = note_dict['createdAt'].isoformat()
        note_dict['updatedAt'] = note_dict['updatedAt'].isoformat()
        
        await db.notes.insert_one(note_dict)
        logger.info(f"Anotação criada: {note.id}")
        return note
    except Exception as e:
        logger.error(f"Erro ao criar anotação: {e}")
        raise HTTPException(status_code=500, detail="Erro ao criar anotação")

@api_router.put("/notes/{note_id}", response_model=Note)
async def update_note(note_id: str, note_data: NoteUpdate):
    """Atualizar anotação existente"""
    try:
        # Check if note exists
        existing_note = await db.notes.find_one({"id": note_id})
        if not existing_note:
            raise HTTPException(status_code=404, detail="Anotação não encontrada")
        
        # Update data
        update_data = note_data.dict()
        update_data['updatedAt'] = datetime.utcnow().isoformat()
        
        await db.notes.update_one(
            {"id": note_id}, 
            {"$set": update_data}
        )
        
        # Return updated note
        updated_note = await db.notes.find_one({"id": note_id})
        logger.info(f"Anotação atualizada: {note_id}")
        return Note(**updated_note)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao atualizar anotação: {e}")
        raise HTTPException(status_code=500, detail="Erro ao atualizar anotação")

@api_router.delete("/notes/{note_id}")
async def delete_note(note_id: str):
    """Excluir anotação"""
    try:
        # Check if note exists
        existing_note = await db.notes.find_one({"id": note_id})
        if not existing_note:
            raise HTTPException(status_code=404, detail="Anotação não encontrada")
        
        await db.notes.delete_one({"id": note_id})
        logger.info(f"Anotação excluída: {note_id}")
        return {"message": "Anotação excluída com sucesso"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao excluir anotação: {e}")
        raise HTTPException(status_code=500, detail="Erro ao excluir anotação")

# Original status check endpoints
@api_router.get("/")
async def root():
    return {"message": "Hello World - Notes API"}

@api_router.post("/status", response_model=StatusCheck)
async def create_status_check(input: StatusCheckCreate):
    status_dict = input.dict()
    status_obj = StatusCheck(**status_dict)
    _ = await db.status_checks.insert_one(status_obj.dict())
    return status_obj

@api_router.get("/status", response_model=List[StatusCheck])
async def get_status_checks():
    status_checks = await db.status_checks.find().to_list(1000)
    return [StatusCheck(**status_check) for status_check in status_checks]

# Include the router in the main app
app.include_router(api_router)

app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@app.on_event("startup")
async def startup_event():
    """Initialize database with sample data if empty"""
    try:
        # Check if notes collection is empty
        notes_count = await db.notes.count_documents({})
        if notes_count == 0:
            logger.info("Inicializando banco com dados de exemplo...")
            
            sample_notes = [
                {
                    "id": str(uuid.uuid4()),
                    "title": "Lista de compras",
                    "content": "Leite, Pão, Ovos, Arroz, Feijão, Carne, Verduras, Frutas. Lembrar de comprar também produtos de limpeza.",
                    "createdAt": datetime.utcnow().isoformat(),
                    "updatedAt": datetime.utcnow().isoformat()
                },
                {
                    "id": str(uuid.uuid4()),
                    "title": "Reunião de trabalho",
                    "content": "Reunião às 14h com a equipe de desenvolvimento. Pontos a discutir: projeto novo, prazos, recursos necessários.",
                    "createdAt": datetime.utcnow().isoformat(),
                    "updatedAt": datetime.utcnow().isoformat()
                },
                {
                    "id": str(uuid.uuid4()),
                    "title": "Ideias para o final de semana", 
                    "content": "Visitar o parque com a família, assistir filme no cinema, fazer churrasco com os amigos, ler o livro novo.",
                    "createdAt": datetime.utcnow().isoformat(),
                    "updatedAt": datetime.utcnow().isoformat()
                },
                {
                    "id": str(uuid.uuid4()),
                    "title": "Exercícios da semana",
                    "content": "Segunda: Caminhada 30min, Terça: Academia, Quarta: Yoga, Quinta: Corrida, Sexta: Academia, Sábado: Bike.",
                    "createdAt": datetime.utcnow().isoformat(),
                    "updatedAt": datetime.utcnow().isoformat()
                },
                {
                    "id": str(uuid.uuid4()),
                    "title": "Lembretes importantes",
                    "content": "Consulta médica na próxima terça (9h), renovar CNH, pagar conta de luz, ligar para o dentista.",
                    "createdAt": datetime.utcnow().isoformat(),
                    "updatedAt": datetime.utcnow().isoformat()
                }
            ]
            
            await db.notes.insert_many(sample_notes)
            logger.info(f"Inseridas {len(sample_notes)} anotações de exemplo")
    except Exception as e:
        logger.error(f"Erro na inicialização: {e}")

@app.on_event("shutdown")
async def shutdown_db_client():
    client.close()