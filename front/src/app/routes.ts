import { createBrowserRouter } from 'react-router';
import Layout from './components/Layout';
import WeeklyView from './screens/WeeklyView';
import MonthlyView from './screens/MonthlyView';
import ListView from './screens/ListView';
import SettingsView from './screens/SettingsView';

export const router = createBrowserRouter([
  {
    path: '/',
    Component: Layout,
    children: [
      { index: true, Component: WeeklyView },
      { path: 'monthly', Component: MonthlyView },
      { path: 'list', Component: ListView },
      { path: 'settings', Component: SettingsView },
    ],
  },
]);
