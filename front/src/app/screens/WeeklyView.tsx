import { useState } from 'react';
import { format, startOfWeek, addDays, isSameDay } from 'date-fns';
import { ko } from 'date-fns/locale';
import { ChevronLeft, ChevronRight, Plus } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { useTranslation } from '../utils/translations';
import DetailModal from '../components/DetailModal';
import { TodoItem, DailyPlan } from '../types';

export default function WeeklyView() {
  const { todos, dailyPlans, language, updateTodo, updateDailyPlan } = useApp();
  const t = useTranslation(language);
  const [currentWeekStart, setCurrentWeekStart] = useState(
    startOfWeek(new Date(), { weekStartsOn: 1 })
  );
  const [selectedItem, setSelectedItem] = useState<{ item: TodoItem | DailyPlan; type: 'todo' | 'plan' } | null>(null);

  const weekDays = Array.from({ length: 7 }, (_, i) => addDays(currentWeekStart, i));

  const getDayName = (day: Date) => {
    const dayNames = [t.monday, t.tuesday, t.wednesday, t.thursday, t.friday, t.saturday, t.sunday];
    return dayNames[day.getDay() === 0 ? 6 : day.getDay() - 1];
  };

  const getTodosForDay = (day: Date) => {
    return todos.filter(todo => isSameDay(new Date(todo.dueDate), day));
  };

  const getPlansForDay = (day: Date) => {
    return dailyPlans.filter(plan => isSameDay(new Date(plan.date), day));
  };

  const goToPreviousWeek = () => {
    setCurrentWeekStart(addDays(currentWeekStart, -7));
  };

  const goToNextWeek = () => {
    setCurrentWeekStart(addDays(currentWeekStart, 7));
  };

  const toggleTodoComplete = (id: string, completed: boolean) => {
    updateTodo(id, { completed: !completed });
  };

  const togglePlanComplete = (id: string, completed: boolean) => {
    updateDailyPlan(id, { completed: !completed });
  };

  return (
    <>
      <div className="h-full flex flex-col bg-white">
      <header className="px-6 py-6 border-b bg-white sticky top-0 z-10">
        <h1 className="text-2xl mb-4">{t.weeklyTodoPlan}</h1>
        <div className="flex items-center justify-between">
          <button
            onClick={goToPreviousWeek}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <ChevronLeft size={20} />
          </button>
          <span className="text-sm text-gray-600">
            {format(currentWeekStart, 'MMM d', { locale: language === 'ko' ? ko : undefined })} -{' '}
            {format(addDays(currentWeekStart, 6), 'MMM d, yyyy', { locale: language === 'ko' ? ko : undefined })}
          </span>
          <button
            onClick={goToNextWeek}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <ChevronRight size={20} />
          </button>
        </div>
      </header>

      <div className="flex-1 overflow-auto px-4 py-4">
        <div className="space-y-3 max-w-md mx-auto">
          {weekDays.map((day, index) => {
            const dayTodos = getTodosForDay(day);
            const dayPlans = getPlansForDay(day);
            const isToday = isSameDay(day, new Date());

            return (
              <div
                key={index}
                className={`border rounded-2xl p-4 ${
                  isToday ? 'border-blue-500 bg-blue-50/30' : 'border-gray-200 bg-white'
                }`}
              >
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center gap-2">
                    <span className={`text-xs px-2 py-1 rounded-full ${
                      isToday ? 'bg-blue-500 text-white' : 'bg-gray-100 text-gray-600'
                    }`}>
                      {getDayName(day)}
                    </span>
                    <span className="text-sm text-gray-600">
                      {format(day, 'M/d', { locale: language === 'ko' ? ko : undefined })}
                    </span>
                  </div>
                  <button className="p-1 hover:bg-gray-100 rounded-lg">
                    <Plus size={18} className="text-gray-500" />
                  </button>
                </div>

                <div className="space-y-4">
                  {dayTodos.length > 0 && (
                    <div>
                      <h3 className="text-xs uppercase text-gray-500 mb-2">
                        {language === 'ko' ? '마감 TODO' : 'Due Today'}
                      </h3>
                      <div className="space-y-2">
                        {dayTodos.map(todo => (
                          <div
                            key={todo.id}
                            className="flex items-start gap-2 p-2 rounded-lg hover:bg-gray-50 cursor-pointer"
                            onClick={(e) => {
                              if ((e.target as HTMLElement).tagName !== 'INPUT') {
                                setSelectedItem({ item: todo, type: 'todo' });
                              }
                            }}
                          >
                            <input
                              type="checkbox"
                              checked={todo.completed}
                              onChange={(e) => {
                                e.stopPropagation();
                                toggleTodoComplete(todo.id, todo.completed);
                              }}
                              className="mt-0.5 rounded"
                            />
                            <div className="flex-1 min-w-0">
                              <p className={`text-sm ${todo.completed ? 'line-through text-gray-400' : 'text-gray-900'}`}>
                                {todo.title}
                              </p>
                              <div className="flex gap-1 mt-1">
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
                        ))}
                      </div>
                    </div>
                  )}

                  {dayPlans.length > 0 && (
                    <div>
                      <h3 className="text-xs uppercase text-gray-500 mb-2">
                        {language === 'ko' ? '오늘 일정' : 'Today\'s Plans'}
                      </h3>
                      <div className="space-y-2">
                        {dayPlans.map(plan => (
                          <div
                            key={plan.id}
                            className="flex items-start gap-2 p-2 rounded-lg hover:bg-gray-50 cursor-pointer border-l-2"
                            style={{ borderColor: plan.labels[0]?.color || '#gray' }}
                            onClick={(e) => {
                              if ((e.target as HTMLElement).tagName !== 'INPUT') {
                                setSelectedItem({ item: plan, type: 'plan' });
                              }
                            }}
                          >
                            <input
                              type="checkbox"
                              checked={plan.completed}
                              onChange={(e) => {
                                e.stopPropagation();
                                togglePlanComplete(plan.id, plan.completed);
                              }}
                              className="mt-0.5 rounded"
                            />
                            <div className="flex-1 min-w-0">
                              <p className={`text-sm ${plan.completed ? 'line-through text-gray-400' : 'text-gray-900'}`}>
                                {plan.title}
                              </p>
                              {plan.startTime && (
                                <p className="text-xs text-gray-500 mt-0.5">
                                  {plan.startTime} {plan.endTime && `- ${plan.endTime}`}
                                </p>
                              )}
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {dayTodos.length === 0 && dayPlans.length === 0 && (
                    <p className="text-xs text-gray-400 text-center py-4">{t.noTodos}</p>
                  )}
                </div>
              </div>
            );
          })}
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
