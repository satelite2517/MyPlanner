import { useState } from 'react';
import { format } from 'date-fns';
import { ko } from 'date-fns/locale';
import { Clock, Calendar } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { useTranslation } from '../utils/translations';
import DetailModal from '../components/DetailModal';
import { TodoItem, DailyPlan } from '../types';

type ViewMode = 'all' | 'todos' | 'plans';

export default function ListView() {
  const { todos, dailyPlans, language, updateTodo, updateDailyPlan } = useApp();
  const t = useTranslation(language);
  const [viewMode, setViewMode] = useState<ViewMode>('all');
  const [selectedItem, setSelectedItem] = useState<{ item: TodoItem | DailyPlan; type: 'todo' | 'plan' } | null>(null);

  const sortedTodos = [...todos].sort((a, b) =>
    new Date(a.dueDate).getTime() - new Date(b.dueDate).getTime()
  );

  const sortedPlans = [...dailyPlans].sort((a, b) =>
    new Date(a.date).getTime() - new Date(b.date).getTime()
  );

  const toggleTodoComplete = (id: string, completed: boolean) => {
    updateTodo(id, { completed: !completed });
  };

  const togglePlanComplete = (id: string, completed: boolean) => {
    updateDailyPlan(id, { completed: !completed });
  };

  return (
    <>
      <div className="h-full flex flex-col bg-white">
      <header className="px-6 py-6 border-b sticky top-0 bg-white z-10">
        <h1 className="text-2xl mb-4">{t.list}</h1>
        <div className="flex gap-2">
          <button
            onClick={() => setViewMode('all')}
            className={`px-4 py-2 rounded-lg text-sm transition-colors ${
              viewMode === 'all' ? 'bg-blue-500 text-white' : 'bg-gray-100 text-gray-600'
            }`}
          >
            {language === 'ko' ? '전체' : 'All'}
          </button>
          <button
            onClick={() => setViewMode('todos')}
            className={`px-4 py-2 rounded-lg text-sm transition-colors ${
              viewMode === 'todos' ? 'bg-blue-500 text-white' : 'bg-gray-100 text-gray-600'
            }`}
          >
            {t.todo}
          </button>
          <button
            onClick={() => setViewMode('plans')}
            className={`px-4 py-2 rounded-lg text-sm transition-colors ${
              viewMode === 'plans' ? 'bg-blue-500 text-white' : 'bg-gray-100 text-gray-600'
            }`}
          >
            {t.plan}
          </button>
        </div>
      </header>

      <div className="flex-1 overflow-auto px-4 py-4">
        <div className="max-w-md mx-auto space-y-6">
          {(viewMode === 'all' || viewMode === 'todos') && sortedTodos.length > 0 && (
            <div>
              {viewMode === 'all' && (
                <h2 className="text-sm uppercase text-gray-500 mb-3 px-2">
                  {language === 'ko' ? '마감 TODO' : 'Due Dates'}
                </h2>
              )}
              <div className="space-y-3">
                {sortedTodos.map(todo => (
                  <div
                    key={todo.id}
                    className="border border-gray-200 rounded-xl p-4 bg-white hover:shadow-sm transition-shadow cursor-pointer"
                    onClick={(e) => {
                      if ((e.target as HTMLElement).tagName !== 'INPUT') {
                        setSelectedItem({ item: todo, type: 'todo' });
                      }
                    }}
                  >
                    <div className="flex items-start gap-3">
                      <input
                        type="checkbox"
                        checked={todo.completed}
                        onChange={(e) => {
                          e.stopPropagation();
                          toggleTodoComplete(todo.id, todo.completed);
                        }}
                        className="mt-1 rounded"
                      />
                      <div className="flex-1 min-w-0">
                        <p className={`text-sm mb-1 ${todo.completed ? 'line-through text-gray-400' : 'text-gray-900'}`}>
                          {todo.title}
                        </p>
                        {todo.description && (
                          <p className="text-xs text-gray-500 mb-2">{todo.description}</p>
                        )}
                        <div className="flex items-center gap-2 flex-wrap">
                          <div className="flex items-center gap-1 text-xs text-gray-500">
                            <Calendar size={14} />
                            <span>{format(new Date(todo.dueDate), 'MMM d, yyyy', { locale: language === 'ko' ? ko : undefined })}</span>
                          </div>
                          {todo.labels.map(label => (
                            <span
                              key={label.id}
                              className="text-xs px-2 py-0.5 rounded-full"
                              style={{ backgroundColor: `${label.color}20`, color: label.color }}
                            >
                              {label.name}
                            </span>
                          ))}
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {(viewMode === 'all' || viewMode === 'plans') && sortedPlans.length > 0 && (
            <div>
              {viewMode === 'all' && (
                <h2 className="text-sm uppercase text-gray-500 mb-3 px-2">
                  {language === 'ko' ? '일정 계획' : 'Scheduled Plans'}
                </h2>
              )}
              <div className="space-y-3">
                {sortedPlans.map(plan => (
                  <div
                    key={plan.id}
                    className="border border-gray-200 rounded-xl p-4 bg-white hover:shadow-sm transition-shadow cursor-pointer"
                    onClick={(e) => {
                      if ((e.target as HTMLElement).tagName !== 'INPUT') {
                        setSelectedItem({ item: plan, type: 'plan' });
                      }
                    }}
                  >
                    <div className="flex items-start gap-3">
                      <input
                        type="checkbox"
                        checked={plan.completed}
                        onChange={(e) => {
                          e.stopPropagation();
                          togglePlanComplete(plan.id, plan.completed);
                        }}
                        className="mt-1 rounded"
                      />
                      <div className="flex-1 min-w-0">
                        <p className={`text-sm mb-1 ${plan.completed ? 'line-through text-gray-400' : 'text-gray-900'}`}>
                          {plan.title}
                        </p>
                        {plan.description && (
                          <p className="text-xs text-gray-500 mb-2">{plan.description}</p>
                        )}
                        <div className="flex items-center gap-2 flex-wrap">
                          <div className="flex items-center gap-1 text-xs text-gray-500">
                            <Calendar size={14} />
                            <span>{format(new Date(plan.date), 'MMM d, yyyy', { locale: language === 'ko' ? ko : undefined })}</span>
                          </div>
                          {plan.startTime && (
                            <div className="flex items-center gap-1 text-xs text-gray-500">
                              <Clock size={14} />
                              <span>{plan.startTime} {plan.endTime && `- ${plan.endTime}`}</span>
                            </div>
                          )}
                          {plan.labels.map(label => (
                            <span
                              key={label.id}
                              className="text-xs px-2 py-0.5 rounded-full"
                              style={{ backgroundColor: `${label.color}20`, color: label.color }}
                            >
                              {label.name}
                            </span>
                          ))}
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {((viewMode === 'all' && todos.length === 0 && dailyPlans.length === 0) ||
            (viewMode === 'todos' && todos.length === 0) ||
            (viewMode === 'plans' && dailyPlans.length === 0)) && (
            <p className="text-center text-gray-400 py-8">{t.noTodos}</p>
          )}
        </div>
      </div>
    </div>

      {selectedItem && (
        <DetailModal
          item={selectedItem.item}
          type={selectedItem.type}
          onClose={() => setSelectedItem(null)}
        />
      )}
    </>
  );
}
