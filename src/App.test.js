import { render, screen } from '@testing-library/react';
import App from './App';

// Test 1: The app renders without crashing
test('renders without crashing', () => {
  render(<App />);
});

// Test 2: The greeting text appears on screen
test('displays the greeting message', () => {
  render(<App />);
  const heading = screen.getByText(/Hello, Umair Rao!/i);
  expect(heading).toBeInTheDocument();
});

// Test 3: The pipeline message appears on screen
test('displays the pipeline message', () => {
  render(<App />);
  const message = screen.getByText(/This app was deployed with a CI\/CD pipeline\./i);
  expect(message).toBeInTheDocument();
});
