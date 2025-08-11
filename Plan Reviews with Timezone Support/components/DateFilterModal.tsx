import { useState } from 'react';
import { Calendar, ChevronDown, ChevronRight, Settings } from 'lucide-react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from './ui/dialog';
import { Button } from './ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Separator } from './ui/separator';
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from './ui/collapsible';
import { useTimezone } from './TimezoneManager';

interface DateFilterModalProps {
  children: React.ReactNode;
  title: string;
  onApplyFilter: (filters: DateFilterOptions) => void;
}

export interface DateFilterOptions {
  fromDate?: string;
  toDate?: string;
  timezone: string;
  filterType: 'range' | 'specific' | 'relative';
  specificDate?: string;
  relativeValue?: number;
  relativeUnit?: 'days' | 'weeks' | 'months';
}

export default function DateFilterModal({ children, title, onApplyFilter }: DateFilterModalProps) {
  const [open, setOpen] = useState(false);
  const [filterType, setFilterType] = useState<'range' | 'specific' | 'relative'>('range');
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');
  const [specificDate, setSpecificDate] = useState('');
  const [relativeValue, setRelativeValue] = useState<number>(7);
  const [relativeUnit, setRelativeUnit] = useState<'days' | 'weeks' | 'months'>('days');
  const [timezoneOpen, setTimezoneOpen] = useState(false);

  const {
    selectedTimezone,
    setSelectedTimezone,
    detectedTimezone,
    commonTimezones
  } = useTimezone();

  const handleApply = () => {
    const filters: DateFilterOptions = {
      timezone: selectedTimezone,
      filterType,
      fromDate: filterType === 'range' ? fromDate : undefined,
      toDate: filterType === 'range' ? toDate : undefined,
      specificDate: filterType === 'specific' ? specificDate : undefined,
      relativeValue: filterType === 'relative' ? relativeValue : undefined,
      relativeUnit: filterType === 'relative' ? relativeUnit : undefined,
    };
    
    onApplyFilter(filters);
    setOpen(false);
  };

  const handleClear = () => {
    setFromDate('');
    setToDate('');
    setSpecificDate('');
    setRelativeValue(7);
    setRelativeUnit('days');
    setFilterType('range');
  };

  const getCurrentTimezoneDisplay = () => {
    const selected = commonTimezones.find(tz => tz.value === selectedTimezone);
    if (selected) {
      return `${selected.label}`;
    }
    return selectedTimezone.replace(/_/g, ' ');
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        {children}
      </DialogTrigger>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Calendar className="h-4 w-4" />
            Filter {title}
          </DialogTitle>
        </DialogHeader>
        
        <div className="space-y-6">
          {/* Filter Type Selector */}
          <div className="space-y-2">
            <Label>Filter Type</Label>
            <Select value={filterType} onValueChange={(value) => setFilterType(value as any)}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="range">Date Range</SelectItem>
                <SelectItem value="specific">Specific Date</SelectItem>
                <SelectItem value="relative">Relative Date</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Filter Options */}
          <div className="space-y-4">
            {filterType === 'range' && (
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>From Date</Label>
                  <Input
                    type="date"
                    value={fromDate}
                    onChange={(e) => setFromDate(e.target.value)}
                  />
                </div>
                <div className="space-y-2">
                  <Label>To Date</Label>
                  <Input
                    type="date"
                    value={toDate}
                    onChange={(e) => setToDate(e.target.value)}
                  />
                </div>
              </div>
            )}

            {filterType === 'specific' && (
              <div className="space-y-2">
                <Label>Date</Label>
                <Input
                  type="date"
                  value={specificDate}
                  onChange={(e) => setSpecificDate(e.target.value)}
                />
              </div>
            )}

            {filterType === 'relative' && (
              <div className="space-y-2">
                <Label>Show items from the last</Label>
                <div className="flex gap-2">
                  <Input
                    type="number"
                    min="1"
                    value={relativeValue}
                    onChange={(e) => setRelativeValue(parseInt(e.target.value) || 1)}
                    className="w-20"
                  />
                  <Select value={relativeUnit} onValueChange={(value) => setRelativeUnit(value as any)}>
                    <SelectTrigger className="w-24">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="days">Days</SelectItem>
                      <SelectItem value="weeks">Weeks</SelectItem>
                      <SelectItem value="months">Months</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
            )}
          </div>

          {/* Advanced Settings - Timezone */}
          <Collapsible open={timezoneOpen} onOpenChange={setTimezoneOpen}>
            <CollapsibleTrigger asChild>
              <Button variant="ghost" className="w-full justify-between p-0 h-auto">
                <div className="flex items-center gap-2">
                  <Settings className="h-3 w-3" />
                  <span className="text-sm">Timezone Settings</span>
                  <span className="text-xs text-muted-foreground">({getCurrentTimezoneDisplay()})</span>
                </div>
                {timezoneOpen ? (
                  <ChevronDown className="h-3 w-3" />
                ) : (
                  <ChevronRight className="h-3 w-3" />
                )}
              </Button>
            </CollapsibleTrigger>
            <CollapsibleContent className="space-y-2 pt-2">
              <Separator />
              <div className="space-y-2">
                <Label className="text-sm">Display timezone</Label>
                <Select value={selectedTimezone} onValueChange={setSelectedTimezone}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {commonTimezones.map((tz) => (
                      <SelectItem key={tz.value} value={tz.value}>
                        {tz.label} ({tz.offset})
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <p className="text-xs text-muted-foreground">
                  Current: {getCurrentTimezoneDisplay()}
                  {detectedTimezone && detectedTimezone !== selectedTimezone && (
                    <Button 
                      variant="link" 
                      className="h-auto p-0 ml-2 text-xs"
                      onClick={() => setSelectedTimezone(detectedTimezone)}
                    >
                      Reset to detected
                    </Button>
                  )}
                </p>
              </div>
            </CollapsibleContent>
          </Collapsible>

          {/* Actions */}
          <div className="flex justify-between pt-4">
            <Button variant="outline" onClick={handleClear}>
              Clear
            </Button>
            <div className="flex gap-2">
              <Button variant="outline" onClick={() => setOpen(false)}>
                Cancel
              </Button>
              <Button onClick={handleApply}>
                Apply Filter
              </Button>
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}