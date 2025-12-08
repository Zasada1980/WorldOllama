import { render, screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import App from './App';

describe('CompanyCheck App - Smoke Tests', () => {
  it('renders main heading', () => {
    render(<App />);
    const heading = screen.getByText(/Check Israeli Companies/i);
    expect(heading).toBeDefined();
  });

  it('renders search input', () => {
    render(<App />);
    const input = screen.getByPlaceholderText(/Enter Company ID/i);
    expect(input).toBeDefined();
  });

  it('renders language switcher', () => {
    render(<App />);
    const heButton = screen.getByText('HE');
    const enButton = screen.getByText('EN');
    const ruButton = screen.getByText('RU');
    expect(heButton).toBeDefined();
    expect(enButton).toBeDefined();
    expect(ruButton).toBeDefined();
  });

  it('renders feature cards', () => {
    render(<App />);
    const fastFeature = screen.getByText(/Fast/i);
    const sourcesFeature = screen.getByText(/6 Sources/i);
    const affordableFeature = screen.getByText(/Affordable/i);
    expect(fastFeature).toBeDefined();
    expect(sourcesFeature).toBeDefined();
    expect(affordableFeature).toBeDefined();
  });
});
