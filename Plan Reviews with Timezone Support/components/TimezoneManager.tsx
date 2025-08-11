import { useState, useEffect } from 'react';

export interface TimezoneInfo {
  value: string;
  label: string;
  offset: string;
}

export const useTimezone = () => {
  const [selectedTimezone, setSelectedTimezone] = useState<string>('UTC'); // Default to UTC instead of empty
  const [detectedTimezone, setDetectedTimezone] = useState<string>('');
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    try {
      const detected = Intl.DateTimeFormat().resolvedOptions().timeZone;
      setDetectedTimezone(detected);
      setSelectedTimezone(detected);
    } catch (error) {
      console.warn('Failed to detect timezone, using UTC as fallback:', error);
      setDetectedTimezone('UTC');
      setSelectedTimezone('UTC');
    } finally {
      setIsLoading(false);
    }
  }, []);

  const isValidTimezone = (timezone: string): boolean => {
    if (!timezone || timezone.trim() === '') return false;
    try {
      // Test if timezone is valid by trying to create a DateTimeFormat
      new Intl.DateTimeFormat('en-US', { timeZone: timezone });
      return true;
    } catch {
      return false;
    }
  };

  const formatDateInTimezone = (date: Date | string, timezone: string): string => {
    // Validate timezone before using it
    const validTimezone = isValidTimezone(timezone) ? timezone : 'UTC';
    const dateObj = typeof date === 'string' ? new Date(date) : date;
    
    try {
      return new Intl.DateTimeFormat('en-US', {
        timeZone: validTimezone,
        month: 'numeric',
        day: 'numeric', 
        year: 'numeric',
        hour: 'numeric',
        minute: '2-digit',
        hour12: true
      }).format(dateObj);
    } catch (error) {
      console.warn('Error formatting date:', error);
      return dateObj.toLocaleString();
    }
  };

  const formatDateOnlyInTimezone = (date: Date | string, timezone: string): string => {
    // Validate timezone before using it
    const validTimezone = isValidTimezone(timezone) ? timezone : 'UTC';
    const dateObj = typeof date === 'string' ? new Date(date) : date;
    
    try {
      return new Intl.DateTimeFormat('en-US', {
        timeZone: validTimezone,
        month: 'numeric',
        day: 'numeric',
        year: 'numeric'
      }).format(dateObj);
    } catch (error) {
      console.warn('Error formatting date:', error);
      return dateObj.toLocaleDateString();
    }
  };

  const getTimezoneOffset = (timezone: string): string => {
    if (!isValidTimezone(timezone)) return '';
    
    try {
      const now = new Date();
      const formatter = new Intl.DateTimeFormat('en', {
        timeZone: timezone,
        timeZoneName: 'longOffset'
      });
      
      const parts = formatter.formatToParts(now);
      const offsetPart = parts.find(part => part.type === 'timeZoneName');
      return offsetPart?.value || '';
    } catch (error) {
      console.warn('Error getting timezone offset:', error);
      return '';
    }
  };

  const commonTimezones: TimezoneInfo[] = [
    { value: 'America/New_York', label: 'Eastern Time', offset: 'UTC-5/-4' },
    { value: 'America/Chicago', label: 'Central Time', offset: 'UTC-6/-5' },
    { value: 'America/Denver', label: 'Mountain Time', offset: 'UTC-7/-6' },
    { value: 'America/Los_Angeles', label: 'Pacific Time', offset: 'UTC-8/-7' },
    { value: 'Europe/London', label: 'London', offset: 'UTC+0/+1' },
    { value: 'Europe/Paris', label: 'Paris', offset: 'UTC+1/+2' },
    { value: 'Asia/Tokyo', label: 'Tokyo', offset: 'UTC+9' },
    { value: 'Asia/Shanghai', label: 'Shanghai', offset: 'UTC+8' },
    { value: 'Australia/Sydney', label: 'Sydney', offset: 'UTC+10/+11' },
    { value: 'UTC', label: 'UTC', offset: 'UTC+0' }
  ];

  const handleTimezoneChange = (newTimezone: string) => {
    if (isValidTimezone(newTimezone)) {
      setSelectedTimezone(newTimezone);
    } else {
      console.warn('Invalid timezone selected:', newTimezone);
    }
  };

  return {
    selectedTimezone,
    setSelectedTimezone: handleTimezoneChange,
    detectedTimezone,
    formatDateInTimezone,
    formatDateOnlyInTimezone,
    getTimezoneOffset,
    commonTimezones,
    isLoading,
    isValidTimezone
  };
};