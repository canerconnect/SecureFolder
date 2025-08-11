import dayjs from 'dayjs';
import isSameOrBefore from 'dayjs/plugin/isSameOrBefore.js';

dayjs.extend(isSameOrBefore);

export function generateSlotsForDate(providerSettings, dateISO, existingBookings) {
  const date = dayjs(dateISO);
  const weekday = date.day();
  const ranges = providerSettings?.workingHours?.[weekday] || [];
  const slotDuration = providerSettings?.slotDurationMinutes || 30;
  const buffer = providerSettings?.bufferMinutes || 0;

  const bookedIntervals = existingBookings
    .filter((b) => b.status !== 'canceled')
    .map((b) => ({ start: dayjs(b.startTime), end: dayjs(b.endTime) }));

  const slots = [];
  for (const [startStr, endStr] of ranges) {
    let cursor = date.hour(Number(startStr.slice(0, 2))).minute(Number(startStr.slice(3, 5))).second(0).millisecond(0);
    const end = date.hour(Number(endStr.slice(0, 2))).minute(Number(endStr.slice(3, 5))).second(0).millisecond(0);

    while (cursor.add(slotDuration, 'minute').isSameOrBefore(end)) {
      const slotStart = cursor;
      const slotEnd = cursor.add(slotDuration, 'minute');
      const slotEndWithBuffer = slotEnd.add(buffer, 'minute');

      const overlaps = bookedIntervals.some((bi) => slotStart.isBefore(bi.end) && slotEndWithBuffer.isAfter(bi.start));
      slots.push({ start: slotStart.toISOString(), end: slotEnd.toISOString(), available: !overlaps });

      cursor = slotEnd; // next slot directly after
    }
  }
  return slots;
}