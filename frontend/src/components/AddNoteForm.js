import React, { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Textarea } from "./ui/textarea";
import { Save, X } from "lucide-react";

const AddNoteForm = ({ onSubmit, onCancel }) => {
  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");

  const handleSubmit = (e) => {
    e.preventDefault();
    if (title.trim() && content.trim()) {
      onSubmit({
        title: title.trim(),
        content: content.trim()
      });
      setTitle("");
      setContent("");
    }
  };

  return (
    <Card className="shadow-xl border-slate-200 bg-white animate-in slide-in-from-top duration-300">
      <CardHeader>
        <CardTitle className="text-xl text-slate-900 flex items-center gap-2">
          <Save className="h-5 w-5" />
          Nova Anotação
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <label className="text-sm font-medium text-slate-700">
              Título
            </label>
            <Input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Digite o título da sua anotação..."
              className="border-slate-200 focus:border-slate-400 h-12"
              required
            />
          </div>
          
          <div className="space-y-2">
            <label className="text-sm font-medium text-slate-700">
              Conteúdo
            </label>
            <Textarea
              value={content}
              onChange={(e) => setContent(e.target.value)}
              placeholder="Escreva sua anotação aqui..."
              className="min-h-32 border-slate-200 focus:border-slate-400 resize-none"
              required
            />
          </div>

          <div className="flex gap-3 pt-4">
            <Button 
              type="submit"
              className="flex-1 h-12 bg-slate-900 hover:bg-slate-800 transition-all duration-200 shadow-lg hover:shadow-xl"
            >
              <Save className="mr-2 h-5 w-5" />
              Salvar Anotação
            </Button>
            <Button 
              type="button"
              variant="outline"
              onClick={onCancel}
              className="px-6 h-12 hover:bg-slate-50 transition-all duration-200"
            >
              <X className="mr-2 h-5 w-5" />
              Cancelar
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
};

export default AddNoteForm;