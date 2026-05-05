export interface Label {
  id: string;
  name: string;
  color: string;
}

export interface TodoItem {
  id: string;
  title: string;
  description?: string;
  dueDate: Date;
  completed: boolean;
  labels: Label[];
  startDate?: Date;
  estimatedDuration?: number;
  notes?: string;
  links?: string[];
}

export interface DailyPlan {
  id: string;
  title: string;
  description?: string;
  date: Date;
  startTime?: string;
  endTime?: string;
  completed: boolean;
  labels: Label[];
  notes?: string;
  links?: string[];
}

export type Language = 'ko' | 'en';
