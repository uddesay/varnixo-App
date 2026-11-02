import { useTheme } from '../../lib/theme';

/*
 * Chart colours per theme. Mirrors the tokens in index.css; kept in JS because
 * SVG chart attributes are rendered before <html data-theme> updates.
 */
const PALETTES = {
  light: {
    primary: '#1a733a',
    fill: '#17bd54',
    compare: '#8fbb9f',
    grid: '#e6f3eb',
    axis: '#577663',
    ink: '#102718',
    surface: '#ffffff',
    line: '#d2e3d8',
    success: '#2e7d4c',
    danger: '#ba3b2f',
    series: ['#1a733a', '#3298a2', '#ce772e', '#3f7f56', '#359157', '#ba3b2f', '#3f8f8a', '#b8798f'],
  },
  dark: {
    primary: '#0fb64c',
    fill: '#367a4f',
    compare: '#5fa077',
    grid: '#203728',
    axis: '#90bea1',
    ink: '#dcf9e6',
    surface: '#0f2016',
    line: '#253e2e',
    success: '#70c98c',
    danger: '#f18070',
    series: ['#0fb64c', '#31c166', '#f4a269', '#34c067', '#3e8d5b', '#f18070', '#6fcfc5', '#e6a2bb'],
  },
} as const;

export type ChartTheme = (typeof PALETTES)['light'] | (typeof PALETTES)['dark'];

export function useChartTheme(): ChartTheme {
  return PALETTES[useTheme().resolved];
}
