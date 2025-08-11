const express = require('express');
const { pool } = require('../config/database');
const { getKundeFromSubdomain } = require('../middleware/auth');

const router = express.Router();

// Get kunde public information
router.get('/info', getKundeFromSubdomain, async (req, res) => {
  try {
    const kunde = req.kunde;

    // Only return public information
    const publicInfo = {
      id: kunde.id,
      name: kunde.name,
      branche: kunde.branche,
      logoUrl: kunde.logo_url,
      primaryColor: kunde.primary_color,
      secondaryColor: kunde.secondary_color
    };

    res.json({ kunde: publicInfo });

  } catch (error) {
    console.error('Get kunde info error:', error);
    res.status(500).json({ error: 'Fehler beim Abrufen der Kundendaten' });
  }
});

// Get kunde contact information
router.get('/contact', getKundeFromSubdomain, async (req, res) => {
  try {
    const kunde = req.kunde;

    const contactInfo = {
      name: kunde.name,
      email: kunde.email,
      telefon: kunde.telefon,
      adresse: kunde.adresse
    };

    res.json({ contact: contactInfo });

  } catch (error) {
    console.error('Get contact info error:', error);
    res.status(500).json({ error: 'Fehler beim Abrufen der Kontaktdaten' });
  }
});

// Get kunde business hours
router.get('/business-hours', getKundeFromSubdomain, async (req, res) => {
  try {
    const kundeId = req.kunde.id;

    const result = await pool.query(
      'SELECT * FROM working_hours WHERE kunde_id = $1 ORDER BY day_of_week, start_time',
      [kundeId]
    );

    const businessHours = result.rows.reduce((acc, row) => {
      const dayNames = ['Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag'];
      acc[dayNames[row.day_of_week]] = {
        isOpen: row.is_working_day,
        openTime: row.start_time,
        closeTime: row.end_time
      };
      return acc;
    }, {});

    res.json({ businessHours });

  } catch (error) {
    console.error('Get business hours error:', error);
    res.status(500).json({ error: 'Fehler beim Abrufen der Geschäftszeiten' });
  }
});

// Get kunde services (placeholder for future expansion)
router.get('/services', getKundeFromSubdomain, async (req, res) => {
  try {
    // This is a placeholder for future service offerings
    // For now, return basic information
    const kunde = req.kunde;
    
    const services = [
      {
        id: 1,
        name: 'Beratung',
        description: 'Professionelle Beratung in unserem Fachgebiet',
        duration: 30,
        price: null // Price not shown in public view
      }
    ];

    res.json({ services });

  } catch (error) {
    console.error('Get services error:', error);
    res.status(500).json({ error: 'Fehler beim Abrufen der Dienstleistungen' });
  }
});

// Get kunde policies
router.get('/policies', getKundeFromSubdomain, async (req, res) => {
  try {
    const kundeId = req.kunde.id;

    // Get settings for policies
    const settingsResult = await pool.query(
      'SELECT cancellation_deadline_hours, min_advance_booking_hours FROM settings WHERE kunde_id = $1',
      [kundeId]
    );

    const settings = settingsResult.rows[0] || {};

    const policies = {
      cancellationPolicy: `Termine können bis zu ${settings.cancellation_deadline_hours || 12} Stunden vor dem Termin storniert werden.`,
      bookingPolicy: `Termine können mindestens ${settings.min_advance_booking_hours || 2} Stunden im Voraus gebucht werden.`,
      privacyPolicy: 'Ihre Daten werden vertraulich behandelt und nur für die Terminbuchung verwendet.',
      termsOfService: 'Mit der Buchung eines Termins stimmen Sie unseren Geschäftsbedingungen zu.'
    };

    res.json({ policies });

  } catch (error) {
    console.error('Get policies error:', error);
    res.status(500).json({ error: 'Fehler beim Abrufen der Richtlinien' });
  }
});

// Get kunde FAQ (placeholder for future expansion)
router.get('/faq', getKundeFromSubdomain, async (req, res) => {
  try {
    const kunde = req.kunde;
    
    const faq = [
      {
        question: 'Wie kann ich einen Termin buchen?',
        answer: 'Wählen Sie einfach ein verfügbares Datum und eine Uhrzeit aus und füllen Sie das Buchungsformular aus.'
      },
      {
        question: 'Kann ich meinen Termin stornieren?',
        answer: 'Ja, Sie können Ihren Termin über den Link in der Bestätigungs-E-Mail stornieren.'
      },
      {
        question: 'Was passiert, wenn ich zu spät komme?',
        answer: 'Bitte kommen Sie pünktlich zu Ihrem Termin. Bei Verspätung kann der Termin gekürzt werden.'
      }
    ];

    res.json({ faq });

  } catch (error) {
    console.error('Get FAQ error:', error);
    res.status(500).json({ error: 'Fehler beim Abrufen der FAQ' });
  }
});

// Get kunde testimonials (placeholder for future expansion)
router.get('/testimonials', getKundeFromSubdomain, async (req, res) => {
  try {
    // This is a placeholder for future customer testimonials
    const testimonials = [];

    res.json({ testimonials });

  } catch (error) {
    console.error('Get testimonials error:', error);
    res.status(500).json({ error: 'Fehler beim Abrufen der Kundenbewertungen' });
  }
});

// Get kunde location information
router.get('/location', getKundeFromSubdomain, async (req, res) => {
  try {
    const kunde = req.kunde;

    const locationInfo = {
      address: kunde.adresse,
      // Add coordinates if available in future
      coordinates: null
    };

    res.json({ location: locationInfo });

  } catch (error) {
    console.error('Get location error:', error);
    res.status(500).json({ error: 'Fehler beim Abrufen der Standortdaten' });
  }
});

// Get kunde social media links (placeholder for future expansion)
router.get('/social-media', getKundeFromSubdomain, async (req, res) => {
  try {
    // This is a placeholder for future social media integration
    const socialMedia = [];

    res.json({ socialMedia });

  } catch (error) {
    console.error('Get social media error:', error);
    res.status(500).json({ error: 'Fehler beim Abrufen der Social Media Links' });
  }
});

module.exports = router;