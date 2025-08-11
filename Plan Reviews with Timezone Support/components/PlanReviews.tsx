import { useState } from 'react';
import { ChevronLeft, Filter, Calendar, ArrowUpDown, Loader2 } from 'lucide-react';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { useTimezone } from './TimezoneManager';
import DateFilterModal, { DateFilterOptions } from './DateFilterModal';

interface PlanReview {
  id: string;
  permitType: string;
  assignedDateTime: string;
  dueDate: string;
  completedDateTime?: string;
}

const mockData: PlanReview[] = [
  {
    id: '1',
    permitType: 'R - Solar Combo',
    assignedDateTime: '2022-09-05T12:00:00Z',
    dueDate: '2022-09-05T23:59:59Z',
    completedDateTime: '2022-09-05T14:30:00Z'
  },
  {
    id: '2',
    permitType: 'R - Solar Combo',
    assignedDateTime: '2023-10-05T12:00:00Z',
    dueDate: '2023-10-05T23:59:59Z',
    completedDateTime: '2023-10-05T15:45:00Z'
  },
  {
    id: '3',
    permitType: 'R - Electrical',
    assignedDateTime: '2023-10-05T12:00:00Z',
    dueDate: '2023-10-05T23:59:59Z',
    completedDateTime: '2023-10-05T16:20:00Z'
  },
  {
    id: '4',
    permitType: 'R - Solar Combo',
    assignedDateTime: '2022-11-07T12:00:00Z',
    dueDate: '2022-11-07T23:59:59Z',
    completedDateTime: '2022-11-07T13:15:00Z'
  },
  {
    id: '5',
    permitType: 'R - Pool Combo',
    assignedDateTime: '2022-09-05T12:00:00Z',
    dueDate: '2022-09-05T23:59:59Z',
    completedDateTime: '2022-09-05T17:00:00Z'
  },
  {
    id: '6',
    permitType: 'R - Generator Electrical',
    assignedDateTime: '2023-10-05T12:00:00Z',
    dueDate: '2023-10-05T23:59:59Z'
  }
];

export default function PlanReviews() {
  const [data] = useState<PlanReview[]>(mockData);
  const [filteredData, setFilteredData] = useState<PlanReview[]>(mockData);
  const [sortField, setSortField] = useState<keyof PlanReview>('assignedDateTime');
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc'>('desc');
  const [activeFilters, setActiveFilters] = useState<{
    assignedDateTime?: DateFilterOptions;
    dueDate?: DateFilterOptions;
    completedDateTime?: DateFilterOptions;
  }>({});
  
  const {
    selectedTimezone,
    setSelectedTimezone,
    formatDateInTimezone,
    formatDateOnlyInTimezone,
    isLoading
  } = useTimezone();

  const handleSort = (field: keyof PlanReview) => {
    if (sortField === field) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortDirection('asc');
    }
  };

  const applyDateFilter = (field: keyof PlanReview, filterOptions: DateFilterOptions) => {
    // Update the global timezone when a filter is applied
    setSelectedTimezone(filterOptions.timezone);
    
    // Store the filter
    setActiveFilters(prev => ({
      ...prev,
      [field]: filterOptions
    }));

    // Apply filtering logic
    let filtered = [...data];
    const newFilters = { ...activeFilters, [field]: filterOptions };

    Object.entries(newFilters).forEach(([filterField, filter]) => {
      if (!filter) return;

      filtered = filtered.filter(item => {
        const itemDate = new Date(item[filterField as keyof PlanReview] as string);
        const now = new Date();

        switch (filter.filterType) {
          case 'range':
            if (filter.fromDate && filter.toDate) {
              const fromDate = new Date(filter.fromDate);
              const toDate = new Date(filter.toDate);
              toDate.setHours(23, 59, 59, 999); // Include the entire end date
              return itemDate >= fromDate && itemDate <= toDate;
            }
            break;
          
          case 'specific':
            if (filter.specificDate) {
              const targetDate = new Date(filter.specificDate);
              const nextDay = new Date(targetDate);
              nextDay.setDate(nextDay.getDate() + 1);
              return itemDate >= targetDate && itemDate < nextDay;
            }
            break;
          
          case 'relative':
            if (filter.relativeValue && filter.relativeUnit) {
              const pastDate = new Date(now);
              switch (filter.relativeUnit) {
                case 'days':
                  pastDate.setDate(pastDate.getDate() - filter.relativeValue);
                  break;
                case 'weeks':
                  pastDate.setDate(pastDate.getDate() - (filter.relativeValue * 7));
                  break;
                case 'months':
                  pastDate.setMonth(pastDate.getMonth() - filter.relativeValue);
                  break;
              }
              return itemDate >= pastDate;
            }
            break;
        }
        return true;
      });
    });

    setFilteredData(filtered);
  };

  const clearFilter = (field: keyof PlanReview) => {
    setActiveFilters(prev => {
      const updated = { ...prev };
      delete updated[field];
      return updated;
    });
    
    // Reapply remaining filters
    let filtered = [...data];
    const remainingFilters = { ...activeFilters };
    delete remainingFilters[field];
    
    // Apply remaining filters...
    setFilteredData(filtered);
  };

  const clearAllFilters = () => {
    setActiveFilters({});
    setFilteredData(data);
  };

  const sortedData = [...filteredData].sort((a, b) => {
    const aValue = a[sortField] || '';
    const bValue = b[sortField] || '';
    
    if (sortField === 'assignedDateTime' || sortField === 'dueDate' || sortField === 'completedDateTime') {
      const aDate = new Date(aValue).getTime();
      const bDate = new Date(bValue).getTime();
      return sortDirection === 'asc' ? aDate - bDate : bDate - aDate;
    }
    
    return sortDirection === 'asc' 
      ? aValue.localeCompare(bValue)
      : bValue.localeCompare(aValue);
  });

  const hasActiveFilters = Object.keys(activeFilters).length > 0;

  // Show loading state while timezone is being detected
  if (isLoading) {
    return (
      <div className="w-full max-w-7xl mx-auto p-6">
        <div className="flex items-center justify-center h-64">
          <div className="flex items-center gap-2">
            <Loader2 className="h-4 w-4 animate-spin" />
            <span>Loading timezone data...</span>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="w-full max-w-7xl mx-auto p-6">
      {/* Header */}
      <div className="flex items-center gap-4 mb-6">
        <Button variant="ghost" size="sm" className="p-2">
          <ChevronLeft className="h-4 w-4" />
        </Button>
        <h1 className="text-xl">Plan Reviews</h1>
      </div>

      {/* Active Filters Summary */}
      {hasActiveFilters && (
        <div className="mb-6 p-4 bg-muted/50 rounded-lg">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2 flex-wrap">
              <span className="text-sm">Active filters:</span>
              {Object.entries(activeFilters).map(([field, filter]) => (
                <Badge key={field} variant="secondary" className="flex items-center gap-1">
                  {field}
                  <button
                    onClick={() => clearFilter(field as keyof PlanReview)}
                    className="ml-1 hover:text-destructive"
                  >
                    ×
                  </button>
                </Badge>
              ))}
            </div>
            <Button variant="outline" size="sm" onClick={clearAllFilters}>
              Clear All
            </Button>
          </div>
        </div>
      )}

      {/* Table Header */}
      <div className="grid grid-cols-5 gap-4 p-4 border-b bg-muted/30">
        <div className="flex items-center gap-2">
          <button 
            onClick={() => handleSort('permitType')}
            className="flex items-center gap-1 hover:text-primary transition-colors"
          >
            PermitType
            <ArrowUpDown className="h-3 w-3" />
          </button>
        </div>
        
        <div className="flex items-center gap-2">
          <button 
            onClick={() => handleSort('assignedDateTime')}
            className="flex items-center gap-1 hover:text-primary transition-colors"
          >
            AssignedDateTime
            <ArrowUpDown className="h-3 w-3" />
          </button>
          <DateFilterModal 
            title="Assigned Date/Time"
            onApplyFilter={(filter) => applyDateFilter('assignedDateTime', filter)}
          >
            <Button variant="ghost" size="sm" className="p-1">
              <Filter className={`h-3 w-3 ${activeFilters.assignedDateTime ? 'text-primary' : ''}`} />
            </Button>
          </DateFilterModal>
        </div>
        
        <div className="flex items-center gap-2">
          <button 
            onClick={() => handleSort('dueDate')}
            className="flex items-center gap-1 hover:text-primary transition-colors"
          >
            DueDate
            <ArrowUpDown className="h-3 w-3" />
          </button>
          <DateFilterModal 
            title="Due Date"
            onApplyFilter={(filter) => applyDateFilter('dueDate', filter)}
          >
            <Button variant="ghost" size="sm" className="p-1">
              <Filter className={`h-3 w-3 ${activeFilters.dueDate ? 'text-primary' : ''}`} />
            </Button>
          </DateFilterModal>
        </div>
        
        <div className="flex items-center gap-2">
          <button 
            onClick={() => handleSort('completedDateTime')}
            className="flex items-center gap-1 hover:text-primary transition-colors"
          >
            CompletedDateTime
            <ArrowUpDown className="h-3 w-3" />
          </button>
          <DateFilterModal 
            title="Completed Date/Time"
            onApplyFilter={(filter) => applyDateFilter('completedDateTime', filter)}
          >
            <Button variant="ghost" size="sm" className="p-1">
              <Filter className={`h-3 w-3 ${activeFilters.completedDateTime ? 'text-primary' : ''}`} />
            </Button>
          </DateFilterModal>
        </div>
        
        <div className="flex items-center justify-end gap-2">
          <span className="text-xs text-muted-foreground">
            {filteredData.length} of {data.length} items
          </span>
        </div>
      </div>

      {/* Data Rows */}
      <div className="divide-y">
        {sortedData.map((review) => (
          <div key={review.id} className="grid grid-cols-5 gap-4 p-4 hover:bg-muted/50 transition-colors">
            <div>
              <Badge variant="outline" className="text-primary border-primary/20">
                {review.permitType}
              </Badge>
            </div>
            <div className="text-sm">
              {formatDateInTimezone(review.assignedDateTime, selectedTimezone)}
            </div>
            <div className="text-sm">
              {formatDateOnlyInTimezone(review.dueDate, selectedTimezone)}
            </div>
            <div className="text-sm">
              {review.completedDateTime 
                ? formatDateInTimezone(review.completedDateTime, selectedTimezone)
                : '-'
              }
            </div>
            <div className="flex justify-end">
              <Button variant="ghost" size="sm">
                <Calendar className="h-4 w-4" />
              </Button>
            </div>
          </div>
        ))}
      </div>

      {filteredData.length === 0 && (
        <div className="text-center py-8 text-muted-foreground">
          No items match the current filters.
        </div>
      )}
    </div>
  );
}