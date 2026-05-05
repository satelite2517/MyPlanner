import { Language } from '../types';

export const translations = {
  ko: {
    weeklyTodoPlan: 'Weekly Todo & Plan',
    monday: '월',
    tuesday: '화',
    wednesday: '수',
    thursday: '목',
    friday: '금',
    saturday: '토',
    sunday: '일',
    todo: 'Todo',
    plan: '계획',
    completed: '완료',
    pending: '진행중',
    monthly: '월간',
    list: '리스트',
    settings: '설정',
    addTodo: 'Todo 추가',
    addPlan: '계획 추가',
    dueDate: '마감일',
    labels: '라벨',
    noTodos: 'Todo가 없습니다',
    noPlans: '계획이 없습니다',
  },
  en: {
    weeklyTodoPlan: 'Weekly Todo & Plan',
    monday: 'Mon',
    tuesday: 'Tue',
    wednesday: 'Wed',
    thursday: 'Thu',
    friday: 'Fri',
    saturday: 'Sat',
    sunday: 'Sun',
    todo: 'Todo',
    plan: 'Plan',
    completed: 'Completed',
    pending: 'Pending',
    monthly: 'Monthly',
    list: 'List',
    settings: 'Settings',
    addTodo: 'Add Todo',
    addPlan: 'Add Plan',
    dueDate: 'Due Date',
    labels: 'Labels',
    noTodos: 'No todos',
    noPlans: 'No plans',
  },
};

export function useTranslation(language: Language) {
  return translations[language];
}
