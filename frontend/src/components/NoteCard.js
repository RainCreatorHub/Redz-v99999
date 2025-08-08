import React, { useState } from "react";
import { Card, CardContent, CardHeader } from "./ui/card";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Textarea } from "./ui/textarea";
import { Trash2, Edit3, Save, X } from "lucide-react";

const NoteCard = ({ note, onDelete, onEdit }) => {
  const [isEditing, setIsEditing] = useState(false);
  const [editTitle, setEditTitle] = useState(note.title);
  const [editContent, setEditContent] = useState(note.content);

  const handleSave = () => {
    if (editTitle.trim() && editContent.trim()) {
      onEdit(note.id, {
        title: editTitle.trim(),
        content: editContent.trim()
      });
      setIsEditing(false);
    }
  };

  const handleCancel = () => {
    setEditTitle(note.title);
    setEditContent(note.content);
    setIsEditing(false);
  };

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  return (
    <Card className="group hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 border-slate-200 bg-white">
      <CardHeader className="pb-3">
        {isEditing ? (
          <Input
            value={editTitle}
            onChange={(e) => setEditTitle(e.target.value)}
            className="font-semibold text-lg border-slate-200 focus:border-slate-400"
            placeholder="Título da nota..."
          />
        ) : (
          <h3 className="font-semibold text-lg text-slate-900 line-clamp-2">
            {note.title}
          </h3>
        )}
        <div className="flex justify-between items-center">
          <p className="text-sm text-slate-500">
            {formatDate(note.createdAt)}
          </p>
          <div className="flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
            {isEditing ? (
              <>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={handleSave}
                  className="h-8 w-8 p-0 hover:bg-green-50 hover:border-green-300"
                >
                  <Save className="h-4 w-4 text-green-600" />
                </Button>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={handleCancel}
                  className="h-8 w-8 p-0 hover:bg-red-50 hover:border-red-300"
                >
                  <X className="h-4 w-4 text-red-600" />
                </Button>
              </>
            ) : (
              <>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => setIsEditing(true)}
                  className="h-8 w-8 p-0 hover:bg-blue-50 hover:border-blue-300"
                >
                  <Edit3 className="h-4 w-4 text-blue-600" />
                </Button>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => onDelete(note.id)}
                  className="h-8 w-8 p-0 hover:bg-red-50 hover:border-red-300"
                >
                  <Trash2 className="h-4 w-4 text-red-600" />
                </Button>
              </>
            )}
          </div>
        </div>
      </CardHeader>
      <CardContent className="pt-0">
        {isEditing ? (
          <Textarea
            value={editContent}
            onChange={(e) => setEditContent(e.target.value)}
            className="min-h-24 border-slate-200 focus:border-slate-400 resize-none"
            placeholder="Escreva sua anotação..."
          />
        ) : (
          <p className="text-slate-700 leading-relaxed line-clamp-4">
            {note.content}
          </p>
        )}
      </CardContent>
    </Card>
  );
};

export default NoteCard;