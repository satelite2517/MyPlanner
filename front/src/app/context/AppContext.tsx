import { createContext, useContext, useState, ReactNode } from 'react';
import { TodoItem, DailyPlan, Label, Language } from '../types';

interface AppContextType {
  todos: TodoItem[];
  dailyPlans: DailyPlan[];
  labels: Label[];
  language: Language;
  setTodos: (todos: TodoItem[]) => void;
  setDailyPlans: (plans: DailyPlan[]) => void;
  setLabels: (labels: Label[]) => void;
  setLanguage: (lang: Language) => void;
  addTodo: (todo: TodoItem) => void;
  updateTodo: (id: string, updates: Partial<TodoItem>) => void;
  deleteTodo: (id: string) => void;
  addDailyPlan: (plan: DailyPlan) => void;
  updateDailyPlan: (id: string, updates: Partial<DailyPlan>) => void;
  deleteDailyPlan: (id: string) => void;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

const defaultLabels: Label[] = [
  { id: '1', name: '업무', color: '#3b82f6' },
  { id: '2', name: '개인', color: '#10b981' },
  { id: '3', name: '긴급', color: '#ef4444' },
  { id: '4', name: '학습', color: '#8b5cf6' },
];

const sampleTodos: TodoItem[] = [
  {
    id: '1',
    title: '프로젝트 기획서 작성',
    description: '다음 주 월요일까지 제출',
    dueDate: new Date(2026, 4, 7),
    completed: false,
    labels: [defaultLabels[0]],
    startDate: new Date(2026, 4, 5),
    notes: '마케팅팀과 협의 필요',
    links: ['https://docs.google.com/document/example'],
  },
  {
    id: '2',
    title: '운동하기',
    dueDate: new Date(2026, 4, 5),
    completed: false,
    labels: [defaultLabels[1]],
    notes: '헬스장 가기',
  },
  {
    id: '3',
    title: '디자인 시안 검토',
    dueDate: new Date(2026, 4, 6),
    completed: false,
    labels: [defaultLabels[0]],
    notes: '디자이너에게 피드백 전달',
    links: ['https://figma.com/example'],
  },
];

const sampleDailyPlans: DailyPlan[] = [
  {
    id: '1',
    title: '아침 미팅',
    date: new Date(2026, 4, 5),
    startTime: '09:00',
    endTime: '10:00',
    completed: false,
    labels: [defaultLabels[0]],
    notes: '주간 계획 논의',
    links: ['https://zoom.us/meeting-example'],
  },
  {
    id: '2',
    title: '코딩 연습',
    date: new Date(2026, 4, 6),
    startTime: '14:00',
    endTime: '16:00',
    completed: false,
    labels: [defaultLabels[3]],
    notes: 'React 튜토리얼 완료하기',
  },
  {
    id: '3',
    title: '점심 약속',
    date: new Date(2026, 4, 5),
    startTime: '12:00',
    endTime: '13:30',
    completed: false,
    labels: [defaultLabels[1]],
    notes: '강남역 근처 레스토랑',
  },
];

export function AppProvider({ children }: { children: ReactNode }) {
  const [todos, setTodos] = useState<TodoItem[]>(sampleTodos);
  const [dailyPlans, setDailyPlans] = useState<DailyPlan[]>(sampleDailyPlans);
  const [labels, setLabels] = useState<Label[]>(defaultLabels);
  const [language, setLanguage] = useState<Language>('ko');

  const addTodo = (todo: TodoItem) => {
    setTodos([...todos, todo]);
  };

  const updateTodo = (id: string, updates: Partial<TodoItem>) => {
    setTodos(todos.map(todo => todo.id === id ? { ...todo, ...updates } : todo));
  };

  const deleteTodo = (id: string) => {
    setTodos(todos.filter(todo => todo.id !== id));
  };

  const addDailyPlan = (plan: DailyPlan) => {
    setDailyPlans([...dailyPlans, plan]);
  };

  const updateDailyPlan = (id: string, updates: Partial<DailyPlan>) => {
    setDailyPlans(dailyPlans.map(plan => plan.id === id ? { ...plan, ...updates } : plan));
  };

  const deleteDailyPlan = (id: string) => {
    setDailyPlans(dailyPlans.filter(plan => plan.id !== id));
  };

  return (
    <AppContext.Provider
      value={{
        todos,
        dailyPlans,
        labels,
        language,
        setTodos,
        setDailyPlans,
        setLabels,
        setLanguage,
        addTodo,
        updateTodo,
        deleteTodo,
        addDailyPlan,
        updateDailyPlan,
        deleteDailyPlan,
      }}
    >
      {children}
    </AppContext.Provider>
  );
}

export function useApp() {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useApp must be used within AppProvider');
  }
  return context;
}
