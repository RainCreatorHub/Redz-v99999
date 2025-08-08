import React, { useState, useEffect } from "react";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Textarea } from "../components/ui/textarea";
import { Plus, Search, BookOpen, Loader2, CheckCircle2, Circle } from "lucide-react";
import { toast } from "../hooks/use-toast";
import { Toaster } from "../components/ui/toaster";
import NoteCard from "../components/NoteCard";
import AddNoteForm from "../components/AddNoteForm";
import { notesApi } from "../services/notesApi";

const NotesPage = () => {
  const [notes, setNotes] = useState([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [showAddForm, setShowAddForm] = useState(false);
  const [filteredNotes, setFilteredNotes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [filterStatus, setFilterStatus] = useState("all"); // all, completed, pending

  // Carregar anotações do backend
  const loadNotes = async () => {
    try {
      setLoading(true);
      setError(null);
      const notesData = await notesApi.getAllNotes();
      setNotes(notesData);
      toast({
        title: "Anotações carregadas!",
        description: `${notesData.length} anotação(ões) encontrada(s).`,
      });
    } catch (error) {
      setError(error.message);
      toast({
        title: "Erro ao carregar",
        description: error.message,
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadNotes();
  }, []);

  useEffect(() => {
    // Filtrar notas baseado na busca e status
    let filtered = notes;

    // Filtrar por termo de busca
    if (searchTerm.trim()) {
      filtered = filtered.filter(note => 
        note.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
        note.content.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    // Filtrar por status de conclusão
    if (filterStatus === "completed") {
      filtered = filtered.filter(note => note.completed);
    } else if (filterStatus === "pending") {
      filtered = filtered.filter(note => !note.completed);
    }

    setFilteredNotes(filtered);
  }, [notes, searchTerm, filterStatus]);

  const handleAddNote = async (noteData) => {
    try {
      const newNote = await notesApi.createNote(noteData);
      setNotes(prev => [newNote, ...prev]);
      setShowAddForm(false);
      toast({
        title: "Nota criada!",
        description: "Sua anotação foi salva permanentemente.",
      });
    } catch (error) {
      toast({
        title: "Erro ao criar",
        description: error.message,
        variant: "destructive",
      });
    }
  };

  const handleDeleteNote = async (noteId) => {
    try {
      await notesApi.deleteNote(noteId);
      setNotes(prev => prev.filter(note => note.id !== noteId));
      toast({
        title: "Nota excluída",
        description: "A anotação foi removida permanentemente.",
        variant: "destructive",
      });
    } catch (error) {
      toast({
        title: "Erro ao excluir",
        description: error.message,
        variant: "destructive",
      });
    }
  };

  const handleEditNote = async (noteId, updatedData) => {
    try {
      const updatedNote = await notesApi.updateNote(noteId, updatedData);
      setNotes(prev => prev.map(note => 
        note.id === noteId ? updatedNote : note
      ));
      toast({
        title: "Nota atualizada!",
        description: "Suas alterações foram salvas permanentemente.",
      });
    } catch (error) {
      toast({
        title: "Erro ao atualizar",
        description: error.message,
        variant: "destructive",
      });
    }
  };

  const handleToggleComplete = async (noteId, completed) => {
    try {
      const updatedNote = await notesApi.toggleComplete(noteId, completed);
      setNotes(prev => prev.map(note => 
        note.id === noteId ? updatedNote : note
      ));
      toast({
        title: completed ? "Anotação concluída!" : "Anotação reativada",
        description: completed 
          ? "Parabéns! Você completou esta anotação." 
          : "Anotação marcada como pendente novamente.",
      });
    } catch (error) {
      toast({
        title: "Erro ao alterar status",
        description: error.message,
        variant: "destructive",
      });
    }
  };

  // Calcular estatísticas
  const completedCount = notes.filter(note => note.completed).length;
  const pendingCount = notes.length - completedCount;

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="h-12 w-12 animate-spin text-slate-600 mx-auto mb-4" />
          <p className="text-lg text-slate-600">Carregando suas anotações...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 flex items-center justify-center">
        <div className="text-center">
          <Card className="p-8 max-w-md">
            <CardContent>
              <h2 className="text-xl font-semibold text-red-600 mb-4">Erro de Conexão</h2>
              <p className="text-slate-600 mb-6">{error}</p>
              <Button onClick={loadNotes} className="w-full">
                Tentar Novamente
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100">
      <div className="container mx-auto px-4 py-8 max-w-4xl">
        {/* Header */}
        <div className="mb-8 text-center">
          <div className="flex items-center justify-center gap-3 mb-4">
            <div className="p-3 bg-slate-900 rounded-2xl shadow-lg">
              <BookOpen className="h-8 w-8 text-white" />
            </div>
            <h1 className="text-4xl font-bold text-slate-900">Minhas Anotações</h1>
          </div>
          <p className="text-slate-600 text-lg mb-4">Organize suas ideias e pensamentos do dia a dia</p>
          
          {/* Estatísticas */}
          {notes.length > 0 && (
            <div className="flex justify-center gap-6 text-sm">
              <div className="flex items-center gap-1">
                <CheckCircle2 className="h-4 w-4 text-green-600" />
                <span className="text-green-600 font-medium">{completedCount} concluídas</span>
              </div>
              <div className="flex items-center gap-1">
                <Circle className="h-4 w-4 text-slate-500" />
                <span className="text-slate-500">{pendingCount} pendentes</span>
              </div>
            </div>
          )}
        </div>

        {/* Search and Filters */}
        <div className="mb-6 space-y-4">
          <div className="relative">
            <Search className="absolute left-3 top-3 h-5 w-5 text-slate-400" />
            <Input
              placeholder="Buscar nas suas anotações..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-10 h-12 text-lg border-slate-200 focus:border-slate-400 transition-colors"
            />
          </div>

          {/* Filter Buttons */}
          <div className="flex justify-center gap-2">
            <Button
              size="sm"
              variant={filterStatus === "all" ? "default" : "outline"}
              onClick={() => setFilterStatus("all")}
              className="h-9"
            >
              Todas ({notes.length})
            </Button>
            <Button
              size="sm"
              variant={filterStatus === "pending" ? "default" : "outline"}
              onClick={() => setFilterStatus("pending")}
              className="h-9"
            >
              <Circle className="mr-1 h-4 w-4" />
              Pendentes ({pendingCount})
            </Button>
            <Button
              size="sm"
              variant={filterStatus === "completed" ? "default" : "outline"}
              onClick={() => setFilterStatus("completed")}
              className="h-9"
            >
              <CheckCircle2 className="mr-1 h-4 w-4" />
              Concluídas ({completedCount})
            </Button>
          </div>
        </div>

        {/* Add Note Button */}
        <div className="mb-8 flex justify-center">
          <Button 
            onClick={() => setShowAddForm(!showAddForm)}
            className="h-12 px-6 text-lg bg-slate-900 hover:bg-slate-800 transition-all duration-200 shadow-lg hover:shadow-xl transform hover:scale-105"
          >
            <Plus className="mr-2 h-5 w-5" />
            {showAddForm ? 'Cancelar' : 'Nova Anotação'}
          </Button>
        </div>

        {/* Add Note Form */}
        {showAddForm && (
          <div className="mb-8 animate-in fade-in duration-300">
            <AddNoteForm 
              onSubmit={handleAddNote}
              onCancel={() => setShowAddForm(false)}
            />
          </div>
        )}

        {/* Notes Grid */}
        {filteredNotes.length === 0 ? (
          <div className="text-center py-12">
            <div className="mb-4 opacity-50">
              <BookOpen className="h-16 w-16 mx-auto text-slate-400" />
            </div>
            <h3 className="text-xl font-semibold text-slate-600 mb-2">
              {searchTerm || filterStatus !== "all" 
                ? 'Nenhuma nota encontrada' 
                : 'Nenhuma anotação ainda'
              }
            </h3>
            <p className="text-slate-500">
              {searchTerm 
                ? 'Tente buscar por outros termos'
                : filterStatus === "completed"
                ? 'Você ainda não concluiu nenhuma anotação'
                : filterStatus === "pending"
                ? 'Todas as suas anotações estão concluídas!'
                : 'Clique em "Nova Anotação" para começar'
              }
            </p>
          </div>
        ) : (
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {filteredNotes.map((note) => (
              <NoteCard
                key={note.id}
                note={note}
                onDelete={handleDeleteNote}
                onEdit={handleEditNote}
                onToggleComplete={handleToggleComplete}
              />
            ))}
          </div>
        )}
      </div>
      <Toaster />
    </div>
  );
};

export default NotesPage;