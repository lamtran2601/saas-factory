import { useEffect, useState } from 'react';
import { cn } from '@saas-factory/utils';

interface Toast {
  id: string;
  title: string;
  description?: string;
  variant?: 'default' | 'destructive' | 'success';
  duration?: number;
}

interface ToasterState {
  toasts: Toast[];
}

// Simple toast store (in a real app, you might use Zustand or similar)
let toasterState: ToasterState = { toasts: [] };
let listeners: Array<(state: ToasterState) => void> = [];

const notify = (listener: (state: ToasterState) => void) => {
  listeners.push(listener);
  return () => {
    listeners = listeners.filter(l => l !== listener);
  };
};

const addToast = (toast: Omit<Toast, 'id'>) => {
  const id = Math.random().toString(36).substr(2, 9);
  const newToast = { ...toast, id };
  
  toasterState.toasts.push(newToast);
  listeners.forEach(listener => listener(toasterState));

  // Auto remove after duration
  const duration = toast.duration || 5000;
  setTimeout(() => {
    removeToast(id);
  }, duration);

  return id;
};

const removeToast = (id: string) => {
  toasterState.toasts = toasterState.toasts.filter(toast => toast.id !== id);
  listeners.forEach(listener => listener(toasterState));
};

// Export toast functions
export const toast = {
  success: (title: string, description?: string) => 
    addToast({ title, description, variant: 'success' }),
  error: (title: string, description?: string) => 
    addToast({ title, description, variant: 'destructive' }),
  info: (title: string, description?: string) => 
    addToast({ title, description, variant: 'default' }),
};

function ToastItem({ toast, onRemove }: { toast: Toast; onRemove: () => void }) {
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    setIsVisible(true);
  }, []);

  const handleRemove = () => {
    setIsVisible(false);
    setTimeout(onRemove, 150); // Wait for animation
  };

  const variantClasses = {
    default: 'bg-background border',
    destructive: 'bg-destructive text-destructive-foreground',
    success: 'bg-green-600 text-white',
  };

  return (
    <div
      className={cn(
        'pointer-events-auto w-full max-w-sm overflow-hidden rounded-lg shadow-lg transition-all duration-150',
        variantClasses[toast.variant || 'default'],
        isVisible ? 'translate-x-0 opacity-100' : 'translate-x-full opacity-0'
      )}
    >
      <div className="p-4">
        <div className="flex items-start">
          <div className="flex-1">
            <p className="text-sm font-medium">{toast.title}</p>
            {toast.description && (
              <p className="mt-1 text-sm opacity-90">{toast.description}</p>
            )}
          </div>
          <button
            onClick={handleRemove}
            className="ml-4 inline-flex text-gray-400 hover:text-gray-600 focus:outline-none"
          >
            <span className="sr-only">Close</span>
            <svg className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path
                fillRule="evenodd"
                d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                clipRule="evenodd"
              />
            </svg>
          </button>
        </div>
      </div>
    </div>
  );
}

export function Toaster() {
  const [state, setState] = useState(toasterState);

  useEffect(() => {
    return notify(setState);
  }, []);

  return (
    <div className="fixed top-0 right-0 z-50 w-full max-w-sm p-4 space-y-4 pointer-events-none">
      {state.toasts.map((toast) => (
        <ToastItem
          key={toast.id}
          toast={toast}
          onRemove={() => removeToast(toast.id)}
        />
      ))}
    </div>
  );
}
