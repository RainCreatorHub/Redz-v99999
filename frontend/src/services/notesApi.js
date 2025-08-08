import axios from "axios";

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;
const API = `${BACKEND_URL}/api`;

export const notesApi = {
  // Buscar todas as anotações
  getAllNotes: async () => {
    try {
      const response = await axios.get(`${API}/notes`);
      return response.data;
    } catch (error) {
      console.error('Erro ao buscar anotações:', error);
      throw new Error('Falha ao carregar anotações');
    }
  },

  // Criar nova anotação
  createNote: async (noteData) => {
    try {
      const response = await axios.post(`${API}/notes`, noteData);
      return response.data;
    } catch (error) {
      console.error('Erro ao criar anotação:', error);
      throw new Error('Falha ao criar anotação');
    }
  },

  // Atualizar anotação existente
  updateNote: async (noteId, noteData) => {
    try {
      const response = await axios.put(`${API}/notes/${noteId}`, noteData);
      return response.data;
    } catch (error) {
      console.error('Erro ao atualizar anotação:', error);
      throw new Error('Falha ao atualizar anotação');
    }
  },

  // Excluir anotação
  deleteNote: async (noteId) => {
    try {
      const response = await axios.delete(`${API}/notes/${noteId}`);
      return response.data;
    } catch (error) {
      console.error('Erro ao excluir anotação:', error);
      throw new Error('Falha ao excluir anotação');
    }
  }
};