import axios from "axios";

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;
const API = `${BACKEND_URL}/api`;

export const notesApi = {
  // Buscar todas as tarefas
  getAllNotes: async () => {
    try {
      const response = await axios.get(`${API}/notes`);
      return response.data;
    } catch (error) {
      console.error('Erro ao buscar tarefas:', error);
      throw new Error('Falha ao carregar tarefas');
    }
  },

  // Criar nova tarefa
  createNote: async (noteData) => {
    try {
      const response = await axios.post(`${API}/notes`, noteData);
      return response.data;
    } catch (error) {
      console.error('Erro ao criar tarefa:', error);
      throw new Error('Falha ao criar tarefa');
    }
  },

  // Atualizar tarefa existente
  updateNote: async (noteId, noteData) => {
    try {
      const response = await axios.put(`${API}/notes/${noteId}`, noteData);
      return response.data;
    } catch (error) {
      console.error('Erro ao atualizar tarefa:', error);
      throw new Error('Falha ao atualizar tarefa');
    }
  },

  // Marcar/desmarcar como concluída
  toggleComplete: async (noteId, completed) => {
    try {
      const response = await axios.patch(`${API}/notes/${noteId}/toggle-complete`, {
        completed
      });
      return response.data;
    } catch (error) {
      console.error('Erro ao alterar status:', error);
      throw new Error('Falha ao alterar status da tarefa');
    }
  },

  // Excluir tarefa
  deleteNote: async (noteId) => {
    try {
      const response = await axios.delete(`${API}/notes/${noteId}`);
      return response.data;
    } catch (error) {
      console.error('Erro ao excluir tarefa:', error);
      throw new Error('Falha ao excluir tarefa');
    }
  }
};