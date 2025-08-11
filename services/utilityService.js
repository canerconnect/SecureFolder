const moment = require('moment');
const { v4: uuidv4 } = require('uuid');

// Generate a secure cancellation token
function generateCancellationToken() {
  return uuidv4();
}

// Calculate token expiration date (default: 30 days)
function calculateTokenExpiration(days = 30) {
  return moment().add(days, 'days').toDate();
}

// Check if a date is in the future
function isDateInFuture(date) {
  return moment(date).isAfter(moment());
}

// Check if a date is today
function isDateToday(date) {
  return moment(date).isSame(moment(), 'day');
}

// Check if a date is tomorrow
function isDateTomorrow(date) {
  return moment(date).isSame(moment().add(1, 'day'), 'day');
}

// Format date for display (DD.MM.YYYY)
function formatDateForDisplay(date) {
  return moment(date).format('DD.MM.YYYY');
}

// Format time for display (HH:mm)
function formatTimeForDisplay(time) {
  return moment(time, 'HH:mm:ss').format('HH:mm');
}

// Format datetime for database (YYYY-MM-DD HH:mm:ss)
function formatDateTimeForDB(date, time) {
  return moment(`${date} ${time}`, 'YYYY-MM-DD HH:mm').format('YYYY-MM-DD HH:mm:ss');
}

// Parse time string to minutes since midnight
function timeToMinutes(timeString) {
  const [hours, minutes] = timeString.split(':').map(Number);
  return hours * 60 + minutes;
}

// Convert minutes since midnight to time string
function minutesToTime(minutes) {
  const hours = Math.floor(minutes / 60);
  const mins = minutes % 60;
  return `${hours.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}`;
}

// Check if a time is within working hours
function isWithinWorkingHours(time, workingHours) {
  const timeMinutes = timeToMinutes(time);
  const startMinutes = timeToMinutes(workingHours.start);
  const endMinutes = timeToMinutes(workingHours.end);
  
  return timeMinutes >= startMinutes && timeMinutes <= endMinutes;
}

// Check if a time conflicts with break times
function conflictsWithBreakTimes(time, breakTimes) {
  const timeMinutes = timeToMinutes(time);
  
  return breakTimes.some(breakTime => {
    const breakStart = timeToMinutes(breakTime.start);
    const breakEnd = timeToMinutes(breakTime.end);
    return timeMinutes >= breakStart && timeMinutes <= breakEnd;
  });
}

// Generate time slots between start and end time
function generateTimeSlots(startTime, endTime, intervalMinutes = 15) {
  const slots = [];
  const startMinutes = timeToMinutes(startTime);
  const endMinutes = timeToMinutes(endTime);
  
  for (let minutes = startMinutes; minutes <= endMinutes; minutes += intervalMinutes) {
    slots.push(minutesToTime(minutes));
  }
  
  return slots;
}

// Calculate appointment duration in minutes
function calculateAppointmentDuration(startTime, endTime) {
  const startMinutes = timeToMinutes(startTime);
  const endMinutes = timeToMinutes(endTime);
  return endMinutes - startMinutes;
}

// Add buffer time to appointment
function addBufferTime(time, bufferMinutes, direction = 'after') {
  const timeMinutes = timeToMinutes(time);
  
  if (direction === 'after') {
    return minutesToTime(timeMinutes + bufferMinutes);
  } else {
    return minutesToTime(timeMinutes - bufferMinutes);
  }
}

// Validate email format
function isValidEmail(email) {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

// Validate phone number format (German format)
function isValidPhoneNumber(phone) {
  const phoneRegex = /^(\+49|0)[0-9\s\-\(\)]{6,20}$/;
  return phoneRegex.test(phone);
}

// Sanitize input string
function sanitizeInput(input) {
  if (typeof input !== 'string') return input;
  
  return input
    .trim()
    .replace(/[<>]/g, '') // Remove potential HTML tags
    .replace(/&/g, '&amp;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;');
}

// Generate a random string
function generateRandomString(length = 8) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  
  return result;
}

// Format file size in human readable format
function formatFileSize(bytes) {
  if (bytes === 0) return '0 Bytes';
  
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

// Check if a string contains only numbers
function isNumeric(str) {
  return /^\d+$/.test(str);
}

// Capitalize first letter of each word
function capitalizeWords(str) {
  return str.replace(/\w\S*/g, (txt) => {
    return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
  });
}

// Generate a slug from a string
function generateSlug(str) {
  return str
    .toLowerCase()
    .replace(/[^a-z0-9 -]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .trim('-');
}

// Check if two time ranges overlap
function doTimeRangesOverlap(range1, range2) {
  const start1 = timeToMinutes(range1.start);
  const end1 = timeToMinutes(range1.end);
  const start2 = timeToMinutes(range2.start);
  const end2 = timeToMinutes(range2.end);
  
  return start1 < end2 && start2 < end1;
}

// Get day of week name in German
function getGermanDayName(date) {
  const days = [
    'Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 
    'Donnerstag', 'Freitag', 'Samstag'
  ];
  return days[moment(date).day()];
}

// Get month name in German
function getGermanMonthName(date) {
  const months = [
    'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
    'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'
  ];
  return months[moment(date).month()];
}

module.exports = {
  generateCancellationToken,
  calculateTokenExpiration,
  isDateInFuture,
  isDateToday,
  isDateTomorrow,
  formatDateForDisplay,
  formatTimeForDisplay,
  formatDateTimeForDB,
  timeToMinutes,
  minutesToTime,
  isWithinWorkingHours,
  conflictsWithBreakTimes,
  generateTimeSlots,
  calculateAppointmentDuration,
  addBufferTime,
  isValidEmail,
  isValidPhoneNumber,
  sanitizeInput,
  generateRandomString,
  formatFileSize,
  isNumeric,
  capitalizeWords,
  generateSlug,
  doTimeRangesOverlap,
  getGermanDayName,
  getGermanMonthName
};