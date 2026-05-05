import { useState } from 'react';
import { format, startOfMonth, endOfMonth, startOfWeek, endOfWeek, addDays, isSameMonth, isSameDay, addMonths, subMonths } from 'date-fns';
import { ko } from 'date-fns/locale';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { useTranslation } from '../utils/translations';
import DetailModal from '../components/DetailModal';
import { TodoItem } from '../types';

export default function MonthlyView() {
  const { todos, language } = useApp();
  const t = useTranslation(language);
  const [currentMonth, setCurrentMonth] = useState(new Date());
  const [selectedItem, setSelectedItem] = useState<TodoItem | null>(null);

  const monthStart = startOfMonth(currentMonth);
  const monthEnd = endOfMonth(currentMonth);
  const calendarStart = startOfWeek(monthStart, { weekStartsOn: 1 });
  const calendarEnd = endOfWeek(monthEnd, { weekStartsOn: 1 });

  const days: Date[] = [];
  let day = calendarStart;
  while (day <= calendarEnd) {
    days.push(day);
    day = addDays(day, 1);
  }

  const getDayTodos = (day: Date) => {
    return todos.filter(todo => {
      const todoDate = new Date(todo.dueDate);
      if (isSameDay(todoDate, day)) return true;

      if (todo.startDate) {
        const startDate = new Date(todo.startDate);
        return day >= startDate && day <= todoDate;
      }
      return false;
    });
  };

  const goToPreviousMonth = () => {
    setCurrentMonth(subMonths(currentMonth, 1));
  };

  const goToNextMonth = () => {
    setCurrentMonth(addMonths(currentMonth, 1));
  };

  const weekDays = [t.monday, t.tuesday, t.wednesday, t.thursday, t.friday, t.saturday, t.sunday];

  return (
    <>
      <div className="h-full flex flex-col bg-white">
      <header className="px-6 py-6 border-b sticky top-0 bg-white z-10">
        <h1 className="text-2xl mb-4">{t.monthly}</h1>
        <div className="flex items-center justify-between">
          <button
            onClick={goToPreviousMonth}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <ChevronLeft size={20} />
          </button>
          <span className="text-sm">
            {format(currentMonth, 'MMMM yyyy', { locale: language === 'ko' ? ko : undefined })}
          </span>
          <button
            onClick={goToNextMonth}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <ChevronRight size={20} />
          </button>
        </div>
      </header>

      <div className="flex-1 overflow-auto p-4">
        <div className="max-w-md mx-auto">
          <div className="grid grid-cols-7 gap-1 mb-2">
            {weekDays.map((day) => (
              <div key={day} className="text-center text-xs text-gray-500 py-2">
                {day}
              </div>
            ))}
          </div>

          <div className="grid grid-cols-7 gap-1">
            {days.map((day, index) => {
              const dayTodos = getDayTodos(day);
              const isCurrentMonth = isSameMonth(day, currentMonth);
              const isToday = isSameDay(day, new Date());

              return (
                <div
                  key={index}
                  className={`aspect-square border rounded-lg p-1 ${
                    isCurrentMonth ? 'bg-white' : 'bg-gray-50'
                  } ${isToday ? 'border-blue-500 bg-blue-50' : 'border-gray-200'}`}
                >
                  <div className={`text-xs text-center mb-1 ${
                    isCurrentMonth ? 'text-gray-900' : 'text-gray-400'
                  } ${isToday ? 'text-blue-600' : ''}`}>
                    {format(day, 'd')}
                  </div>
                  <div className="space-y-0.5">
                    {dayTodos.slice(0, 2).map(todo => (
                      <div
                        key={todo.id}
                        className="text-[10px] px-1 py-0.5 rounded truncate cursor-pointer hover:opacity-80"
                        style={{
                          backgroundColor: todo.labels[0]?.color ? `${todo.labels[0].color}20` : '#f3f4f6',
                          color: todo.labels[0]?.color || '#6b7280',
                        }}
                        onClick={() => setSelectedItem(todo)}
                      >
                        {todo.title}
                      </div>
                    ))}
                    {dayTodos.length > 2 && (
                      <div className="text-[10px] text-gray-400 text-center">
                        +{dayTodos.length - 2}
                      </div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>

      {selectedItem && (
        <DetailModal
          item={selectedItem}
          type="todo"
          onClose={() => setSelectedItem(null)}
        />
      )}
    </>
  );
}
