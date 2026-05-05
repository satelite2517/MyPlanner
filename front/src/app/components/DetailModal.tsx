import { X, Calendar, Clock, Link as LinkIcon, FileText } from 'lucide-react';
import { format } from 'date-fns';
import { ko } from 'date-fns/locale';
import { TodoItem, DailyPlan } from '../types';
import { useApp } from '../context/AppContext';

interface DetailModalProps {
  item: TodoItem | DailyPlan | null;
  type: 'todo' | 'plan';
  onClose: () => void;
}

export default function DetailModal({ item, type, onClose }: DetailModalProps) {
  const { language, updateTodo, updateDailyPlan } = useApp();

  if (!item) return null;

  const toggleComplete = () => {
    if (type === 'todo') {
      updateTodo(item.id, { completed: !item.completed });
    } else {
      updateDailyPlan(item.id, { completed: !item.completed });
    }
  };

  const isTodo = type === 'todo';
  const todoItem = isTodo ? (item as TodoItem) : null;
  const planItem = !isTodo ? (item as DailyPlan) : null;

  return (
    <div className="fixed inset-0 bg-black/50 flex items-end z-50" onClick={onClose}>
      <div
        className="bg-white w-full max-w-md mx-auto rounded-t-3xl max-h-[85vh] overflow-auto"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="sticky top-0 bg-white border-b px-6 py-4 flex items-center justify-between">
          <h2 className="text-lg">
            {language === 'ko' ? '상세 정보' : 'Details'}
          </h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 rounded-full transition-colors"
          >
            <X size={20} />
          </button>
        </div>

        <div className="p-6 space-y-6">
          <div className="flex items-start gap-3">
            <input
              type="checkbox"
              checked={item.completed}
              onChange={toggleComplete}
              className="mt-1 w-5 h-5 rounded"
            />
            <div className="flex-1">
              <h3 className={`text-xl mb-2 ${item.completed ? 'line-through text-gray-400' : 'text-gray-900'}`}>
                {item.title}
              </h3>
              {item.description && (
                <p className="text-sm text-gray-600">{item.description}</p>
              )}
            </div>
          </div>

          <div className="space-y-3">
            {isTodo && todoItem && (
              <div className="flex items-center gap-3 text-sm">
                <Calendar size={18} className="text-gray-500" />
                <span className="text-gray-700">
                  {language === 'ko' ? '마감일: ' : 'Due: '}
                  {format(new Date(todoItem.dueDate), 'PPP', { locale: language === 'ko' ? ko : undefined })}
                </span>
              </div>
            )}

            {!isTodo && planItem && (
              <>
                <div className="flex items-center gap-3 text-sm">
                  <Calendar size={18} className="text-gray-500" />
                  <span className="text-gray-700">
                    {format(new Date(planItem.date), 'PPP', { locale: language === 'ko' ? ko : undefined })}
                  </span>
                </div>
                {planItem.startTime && (
                  <div className="flex items-center gap-3 text-sm">
                    <Clock size={18} className="text-gray-500" />
                    <span className="text-gray-700">
                      {planItem.startTime} {planItem.endTime && `- ${planItem.endTime}`}
                    </span>
                  </div>
                )}
              </>
            )}

            {item.labels.length > 0 && (
              <div className="flex items-center gap-2">
                <div className="flex gap-2 flex-wrap">
                  {item.labels.map((label) => (
                    <span
                      key={label.id}
                      className="text-sm px-3 py-1 rounded-full"
                      style={{ backgroundColor: `${label.color}20`, color: label.color }}
                    >
                      {label.name}
                    </span>
                  ))}
                </div>
              </div>
            )}
          </div>

          {item.notes && (
            <div className="bg-gray-50 rounded-xl p-4">
              <div className="flex items-start gap-2 mb-2">
                <FileText size={18} className="text-gray-500 mt-0.5" />
                <span className="text-sm text-gray-700">
                  {language === 'ko' ? '메모' : 'Notes'}
                </span>
              </div>
              <p className="text-sm text-gray-800 whitespace-pre-wrap ml-6">{item.notes}</p>
            </div>
          )}

          {item.links && item.links.length > 0 && (
            <div className="space-y-2">
              <div className="flex items-center gap-2 mb-2">
                <LinkIcon size={18} className="text-gray-500" />
                <span className="text-sm text-gray-700">
                  {language === 'ko' ? '링크' : 'Links'}
                </span>
              </div>
              {item.links.map((link, index) => (
                <a
                  key={index}
                  href={link}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="block ml-6 text-sm text-blue-600 hover:underline break-all"
                >
                  {link}
                </a>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
