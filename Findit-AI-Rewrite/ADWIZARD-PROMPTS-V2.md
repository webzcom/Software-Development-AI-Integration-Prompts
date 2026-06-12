# AdWizard — Full Solution Reproduction Prompts (v2)

This file contains an updated, complete set of prompts for building the
**AdWizard** classified-ads solution from scratch with any AI coding
assistant. It reflects the full current state of the solution: the
persona-driven multi-step wizard, real photo uploads with a PHP 5.3 backend,
public/private text fields, anti-spam measures, the Classic ASP host page,
and the database-backed save endpoint.

This supersedes the earlier `ADWIZARD-PROMPTS.md` — Steps 1–3 here replace
those steps with the final field set (character counters, "insert example",
public/private visibility, photo uploads, honeypot, double-submit guard), and
Steps 4–8 are new.

---

## Architecture overview

```
┌─────────────────────────┐
│  post-ad.asp              │  Auth cookie check, generates/retrieves SSO
│  (Classic ASP host page)  │  token, serves AdWizard + window.ADWIZARD_CONFIG
└───────────┬───────────────┘
            │
            ▼
┌─────────────────────────┐
│  adwizard.html/css/js     │  Category picker → dynamic Q&A wizard →
│                            │  Review → Submit
└──────┬──────────────┬─────┘
       │              │
       │ per photo    │ on submit
       ▼              ▼
┌──────────────┐  ┌──────────────┐
│ upload-photo  │  │  save-ad.php  │
│     .php      │  │               │
│ (PHP 5.3,     │  │ (PHP 5.3,     │
│  GD resize,   │  │  rate limit,  │
│  fixed legacy │  │  honeypot,    │
│  big/thumbs   │  │  content      │
│  folders)     │  │  screen, JSON │
│               │  │  insert)      │
└──────────────┘  └──────────────┘
                          │
                          ▼
                  classified_ads table
                  (ad_data JSON column)
```

---

## How to use this file

Run the steps in order in a single conversation with your AI assistant. Each
fenced block is a complete, copy-pasteable prompt.

1. **Step 1** — core wizard HTML/CSS/JS with all field types, including
   character counters, "insert example", public/private badges, photo
   uploads (with a local-preview fallback), honeypot, and a double-submit
   guard.
2. **Step 2** — the category persona JSON schema + five example category
   files (Vehicles, Real Estate, Jobs, Services, Merchandise) using every
   field property from Step 1.
3. **Step 3** — visual design pass (category accent colors, theming).
4. **Step 4** — Classic ASP host page with the authentication cookie check
   and `window.ADWIZARD_CONFIG`.
5. **Step 5** — `upload-photo.php`, the PHP 5.3 image-resize endpoint using
   fixed legacy folder paths and IP+timestamp filenames.
6. **Step 6** — `save-ad.php`, the PHP 5.3 save endpoint with rate limiting,
   honeypot rejection, and content screening.
7. **Step 7** — the `classified_ads` database schema.
8. **Step 8** — persona generation template for adding new categories later.
9. **Step 9** — README generation prompt.

---

## Step 1 — Core Wizard Application (HTML + CSS + JS)

```text
You are a senior software developer with 10+ years building custom web
applications that are HTML5 and Vanilla JavaScript based.

Build a solution made up of a single HTML file plus a separate CSS file and a
separate JavaScript file that the HTML file references. Ensure the
application works with CORS rules by using external CSS/JS file references,
and use JavaScript event listeners on DOM elements for all interactivity (no
inline onclick attributes).

Build an interactive web application called "AdWizard" — a guided, multi-step
classified ad submission flow.

STEP 0 — CHOOSE A CATEGORY
Show a grid of category cards (Vehicles, Real Estate, Jobs, Services,
Merchandise). Clicking a category card loads a corresponding "category
persona" JSON object that defines every subsequent step of the wizard for
that category (see Step 2 of this prompt series for the schema and example
files). Below the grid, include a collapsible "Have a custom category file?"
section with a drag-and-drop / click-to-browse zone that accepts a .json
file, validates it against the category schema, and loads it the same way as
a built-in category.

Also include a hidden honeypot field at the top of the page:
  <div class="honeypot" aria-hidden="true" style="position:absolute;left:-9999px;width:1px;height:1px;overflow:hidden;">
    <label for="f-website">Website</label>
    <input type="text" id="f-website" name="website" tabindex="-1" autocomplete="off" />
  </div>
Real users never see or fill this in. It must be included (empty) in the
final submission payload as "website": "" — a bot that auto-fills every field
will populate it, signaling the backend to reject the submission.

GUIDELINES STEP
After a category is chosen, show a "Before you start" step displaying that
persona's guidelines: a "Not allowed" list (guidelines.prohibited), a "Have
these ready" list (guidelines.requiredDocs), and a tip (guidelines.extra). A
"Get Started" button proceeds to the first dynamic step.

DYNAMIC STEPS — DRIVEN BY THE LOADED PERSONA
Render one wizard step card per entry in the persona's `steps` array. Each
step has a title, tagline, description, and a list of `fields`. Support these
field types:

  - "text", "tel", "email", "date" — standard inputs. If the field has
    maxLength, add a maxlength attribute.
  - "number" — <input type="number">, respecting min/max.
  - "textarea" — <textarea>, with these optional enhancements:
      - maxLength: add maxlength attribute AND a live character counter
        below the field ("123 / 1000"), turning red/bold when at the limit.
      - exampleText: show an "Insert example" button next to the counter
        that fills the textarea with this text (and updates the counter) when
        clicked.
      - visibility: "public" or "private". Show a small badge next to the
        field label: "🌐 Public" (light blue) for public, "🔒 Registered
        users only" (light pink) for private. For "public" textareas, run a
        live regex check for email addresses, phone numbers, or URLs in the
        text; if found, show an inline warning below the field: "⚠️ This
        looks like contact info — move it to a 'Registered Users Only' field
        instead so it isn't shown to everyone."
  - "select" — <select> populated from `options`.
  - "radio" — a responsive grid of bordered option cards, one per `options`
    entry, that highlight when selected.
  - "checkbox" — same option-card grid but multi-select, storing an array of
    selected values.
  - "file" — a photo upload field (see PHOTO UPLOAD HANDLING below). Respect
    `maxFiles` (default 10) as the maximum number of photos for this field.

PHOTO UPLOAD HANDLING (file fields)
Maintain a global config object:
  const ADWIZARD_CONFIG = window.ADWIZARD_CONFIG || {
    userId: 'demo-user',
    ssoToken: 'demo-sso-token',
    csrfToken: 'demo-csrf-token',
    uploadEndpoint: null,   // e.g. "/php/upload-photo.php"
    deleteEndpoint: null,   // e.g. "/php/delete-photo.php"
    saveEndpoint: null      // e.g. "/php/save-ad.php"
  };

When a file-type field's input changes:
  - For each newly selected file (up to maxFiles minus however many photos
    are already attached — if the user selected more than the remaining
    slots, show a toast and only take the first N), push a placeholder entry
    {id, originalName, status:'uploading', thumbUrl:null, bigUrl:null,
    fileName:null, localPreview:null, error:null} into that field's answer
    array and render a thumbnail grid showing each photo with its status.
  - If ADWIZARD_CONFIG.uploadEndpoint is set: POST the file via fetch() as
    multipart/form-data (field name "photo", plus a "userId" field) with
    headers X-SSO-Token and X-CSRF-Token from ADWIZARD_CONFIG. On a JSON
    response {success:true, fileName, thumbUrl, bigUrl}, update the entry to
    status:'done' and store those values; render the returned thumbUrl as the
    thumbnail image. On failure, set status:'error' and show the error
    message under that thumbnail.
  - If ADWIZARD_CONFIG.uploadEndpoint is null (standalone/prototype mode):
    read the file locally with FileReader.readAsDataURL(), wait ~350ms to
    simulate an upload, then set status:'done', fileName:originalName,
    thumbUrl/bigUrl/localPreview: the data URL. Show a small "Preview only
    (prototype)" label under the thumbnail in this mode.
  - Each thumbnail has a ✕ remove button that splices it from the answer
    array, re-renders, and (if deleteEndpoint is set and the file was
    uploaded) POSTs to deleteEndpoint to clean up server-side files.

REVIEW & SUBMIT STEP
After the last persona-defined step, show a "Review & Submit" step that
renders a read-only summary of every answer, grouped by the step it came
from, with an "Edit" link per group that jumps back to that step. For
textarea fields with `visibility`, show the same Public/Private badge next to
the field label in the review. For file fields, show a row with a strip of
small thumbnail images (using each photo's thumbUrl or localPreview). At the
bottom, a "Submit Listing" button.

SUBMIT BEHAVIOR
On "Submit Listing":
  - Immediately disable the button and change its text to "Posting…"
    (double-submit guard). If any photo is still status:'uploading', re-enable
    the button, restore its text, and show a toast asking the user to wait —
    do not submit.
  - Build the payload:
      {
        category: <persona slug>,
        submittedAt: <ISO 8601 timestamp>,
        listingTier: <selected tier, see sidebar below>,
        userId: ADWIZARD_CONFIG.userId,
        answers: { ...field id -> value, with file fields as arrays of
                   {fileName, originalName, thumbUrl, bigUrl, status} (omit
                   thumbUrl/bigUrl — set to null — when uploadEndpoint is
                   null, since those are local data URLs) },
        website: <honeypot field's current value, should be empty>
      }
  - If ADWIZARD_CONFIG.saveEndpoint is set: POST this payload as JSON to
    saveEndpoint with X-SSO-Token/X-CSRF-Token headers. On
    {success:true, adId, status}, show a confirmation with the ad ID and
    status (if status is "pending_review", note that it's awaiting
    moderation). On failure, re-enable the button and show the server's error
    in a toast.
  - If saveEndpoint is null (prototype mode): log the payload to the console,
    display it pretty-printed on screen, and show a success toast: "Listing
    submitted! (Prototype — no server connected yet)". Include a "Start a new
    listing" button that resets back to the category step.

NAVIGATION
A header with pill-shaped step indicators (Category → Guidelines → one pill
per persona step → Review) reflecting progress; completed steps show a
checkmark. Each step card has Next/Back buttons. Clicking "Next" on a
persona step validates that step's required fields — if any are empty, add a
visible error state to those fields and show a toast, without navigating.

RIGHT-HAND SIDEBAR (sticky, shown once a category is chosen):
  - "Listing preview" — a live mock ad card (title, price, category badge,
    description) built from the persona's listingDefaults
    (titleFieldId/priceFieldId/descriptionFieldId). If any photo has a
    thumbUrl/localPreview, show it as the card's image with a photo-count
    badge; otherwise show a placeholder icon.
  - "Progress" — one dot per wizard step, filling green as each becomes
    complete, plus a progress bar and "X / N steps complete" label.
  - "Listing options" — three selectable pricing tier cards: Basic (Free, 14
    days, up to 5 photos), Featured ($9.99, 30 days, up to 12 photos,
    highlighted placement), Premium ($24.99, 60 days, unlimited photos, top
    placement + "Verified Seller" badge). Show the selected tier's price as a
    "Total due at publish" line.
  - "Posting tips" — a short static bulleted list of tips.

A toast notification element at the bottom of the screen for success/error
messages.

Use semantic HTML5, a light theme, and ensure every interactive element has
an appropriate ARIA label. Output three files: adwizard.html, adwizard.css,
adwizard.js.
```

---

## Step 2 — Category Persona Schema + Example Category Files

```text
Add a category-persona loading system to AdWizard:

1. JSON SCHEMA: Create personas/category-schema.json (JSON Schema draft-07)
   describing the category persona file format:

   - meta: { name (required), slug (required), description (required), icon
     (emoji), version, author, tags (array of strings) }

   - listingDefaults: { titleFieldId, priceFieldId (or "" if the category has
     no price, e.g. Jobs), descriptionFieldId }

   - guidelines: { prohibited (array of strings), requiredDocs (array of
     strings), extra (string) }

   - steps: array of { id (unique), title, tagline, description, fields }

   - Each field: { id (unique within the persona), label, type, required
     (boolean), placeholder, helpText, options (required for
     select/radio/checkbox), min/max (for number), and these additional
     properties:
       - maxLength (integer): for text/textarea — max character length,
         shown as a live counter on textareas.
       - exampleText (string): for textarea — if present, shows an "Insert
         example" button.
       - visibility ("public" | "private"): for textarea — controls the
         badge shown and whether the contact-info warning applies.
       - maxFiles (integer): for file fields — max number of photos
         (default 10).
     `type` must be one of: text, textarea, number, select, radio, checkbox,
     tel, email, date, file.

2. Create the following 5 persona files in personas/, each conforming to the
   schema:

   a) personas/vehicles.json — "Vehicle for Sale" (slug "vehicles", icon 🚗).
      listingDefaults: titleFieldId "headline", priceFieldId "askingPrice",
      descriptionFieldId "description".
      guidelines.prohibited: ["Stolen vehicles","Vehicles without a valid
      title","Salvage vehicles not disclosed as such"]. requiredDocs:
      ["VIN (Vehicle Identification Number)","Title status (Clean / Salvage /
      Rebuilt / Lien)"].
      Steps:
        - "Vehicle Details": headline (text, required, maxLength 100), make
          (text, required), model (text, required), year (number, required,
          min 1950, max 2027), mileage (number, required, min 0), vin (text,
          required, helpText about where to find it), bodyType (select:
          Sedan, SUV, Truck, Coupe, Van, Motorcycle, Other — required)
        - "Condition & History": condition (radio: Excellent, Good, Fair,
          Needs Work, For Parts — required), titleStatus (select: Clean,
          Salvage, Rebuilt, Lien — required), accidentHistory (radio: Yes, No
          — required), features (checkbox: A/C, Heated Seats, Sunroof,
          Navigation, Backup Camera, Bluetooth, Leather Seats — optional),
          description (textarea, required, maxLength 1000, visibility
          "public", placeholder about describing condition honestly,
          exampleText: a realistic multi-line example ad for a 2015 Toyota
          Camry SE describing mileage, features, condition, price, and a
          contact time)
        - "Price & Photos": askingPrice (number, required, min 0), negotiable
          (radio: Yes, No — required), photos (file, required, maxFiles 3,
          helpText "Up to 3 photos. Images are resized automatically after
          upload.")
        - "Contact Info": contactName (text, required), contactPhone (tel,
          required), contactEmail (email, required), preferredContact (radio:
          Phone, Email, Text — required), zipCode (text, required), and
          privateNotes (textarea, maxLength 300, visibility "private", label
          "Notes for Registered Users Only", helpText about this only being
          visible to logged-in users — a safer place for contact details than
          the public description)

   b) personas/real-estate.json — "Real Estate / Rental" (slug "real-estate",
      icon 🏠). guidelines.prohibited: ["Discriminatory housing language
      (Fair Housing Act compliance required)","Properties not owned or
      authorized for listing by the poster"]. requiredDocs: ["Proof of
      ownership or property management authorization"].
      Steps:
        - "Property Details": headline (text, required, maxLength 100),
          listingType (radio: For Sale, For Rent — required), propertyType
          (select: House, Apartment, Condo, Townhouse, Land, Commercial —
          required), bedrooms (number, min 0), bathrooms (number, min 0),
          squareFootage (number, min 0)
        - "Location": address (text, required), city (text, required), state
          (text, required), zipCode (text, required)
        - "Description & Amenities": description (textarea, required,
          maxLength 1000, visibility "public", exampleText: a realistic
          example for a bright 2BR/1BA apartment near downtown), amenities
          (checkbox: Parking, Pool, Gym, Pet Friendly, In-Unit Laundry, Air
          Conditioning, Furnished — optional), photos (file, required,
          maxFiles 3, helpText "Up to 3 photos...")
        - "Price & Availability": price (number, required, min 0), priceType
          (select: Total Price, Per Month, Per Night — required),
          availableDate (date, required)
        - "Contact Info": contactName (text, required), contactPhone (tel,
          required), contactEmail (email, required), preferredContact (radio:
          Phone, Email, Text — required), privateNotes (textarea, maxLength
          300, visibility "private", same as above)

   c) personas/jobs.json — "Job Listing" (slug "jobs", icon 💼).
      listingDefaults.priceFieldId = "". guidelines.prohibited: ["Pyramid
      schemes or MLM recruitment","Jobs requiring upfront payment from
      applicants","Discriminatory requirements unrelated to job function"].
      Steps:
        - "Job Details": jobTitle (text, required, maxLength 100),
          companyName (text, required), employmentType (select: Full-time,
          Part-time, Contract, Temporary, Internship — required),
          workArrangement (radio: On-site, Remote, Hybrid — required)
        - "Compensation & Requirements": salaryMin (number, min 0), salaryMax
          (number, min 0), salaryPeriod (select: Per Hour, Per Year —
          required), requirements (textarea, required, placeholder about
          listing required skills/experience)
        - "Description": description (textarea, required, maxLength 1000,
          visibility "public", exampleText: a realistic example for a Front
          Desk Associate role)
        - "Application Info": applyMethod (radio: Email, External Link, In
          Person — required), applyContact (text, required, helpText "Email
          address, URL, or address depending on method chosen"), zipCode
          (text, required)
      (No photos field and no privateNotes field — jobs don't need photo
      uploads, and applyContact already serves the private-contact purpose.)

   d) personas/services.json — "Service Provider" (slug "services", icon
      🛠️). guidelines.prohibited: ["Services requiring licenses you do not
      hold (e.g. electrical, plumbing) without disclosure","Multi-level
      marketing opportunities disguised as services"].
      Steps:
        - "Service Details": headline (text, required, maxLength 100),
          serviceCategory (select: Home Improvement, Cleaning, Lawn & Garden,
          Moving, Tutoring, Pet Care, Tech Support, Other — required),
          yearsExperience (number, min 0)
        - "Availability & Area": serviceArea (text, required, helpText
          "Cities or zip codes you serve"), availability (checkbox: Weekdays,
          Weekends, Evenings, On-call — optional)
        - "Pricing & Description": pricingModel (radio: Hourly Rate, Flat
          Rate, Free Estimate — required), rate (number, min 0), description
          (textarea, required, maxLength 1000, visibility "public",
          exampleText: a realistic example for an experienced house cleaner),
          photos (file, maxFiles 3, label "Photos (optional)", helpText "Up
          to 3 photos — e.g. before/after examples of your work")
        - "Contact Info": contactName (text, required), contactPhone (tel,
          required), contactEmail (email, required), preferredContact (radio:
          Phone, Email, Text — required), privateNotes (textarea, maxLength
          300, visibility "private", same as above)

   e) personas/merchandise.json — "General Merchandise" (slug "merchandise",
      icon 🛍️). guidelines.prohibited: ["Counterfeit goods","Recalled
      products","Weapons, ammunition, or hazardous materials","Live
      animals"].
      Steps:
        - "Item Details": headline (text, required, maxLength 100),
          itemCategory (select: Electronics, Furniture, Clothing &
          Accessories, Toys & Games, Sports & Outdoors, Tools, Books & Media,
          Other — required), condition (radio: New, Like New, Good, Fair, For
          Parts — required)
        - "Description & Photos": description (textarea, required, maxLength
          1000, visibility "public", exampleText: a realistic example for an
          IKEA bookshelf listing), photos (file, required, maxFiles 3,
          helpText "Up to 3 photos. Images are resized automatically after
          upload.")
        - "Price": price (number, required, min 0), negotiable (radio: Yes,
          No — required)
        - "Contact Info": contactName (text, required), contactPhone (tel,
          optional), contactEmail (email, required), preferredContact (radio:
          Email, Phone — required), zipCode (text, required), privateNotes
          (textarea, maxLength 300, visibility "private", same as above)

Validate every persona file against category-schema.json — every field's
`type` must be a valid enum value, select/radio/checkbox fields must have
options, and the exampleText values should be realistic, multi-line where
appropriate, and never contain real personal information.
```

---

## Step 3 — Visual Design Pass

```text
The AdWizard application looks plain. Update adwizard.css to make it more
colorful and improve usability:

1. Light theme: background #f4f6fb, card surfaces white and #f8f9fd, with a
   subtle 40px grid-line background pattern at low opacity.

2. Assign each category its own accent color, applied to that category's
   card and (once loaded) the active theme via CSS custom properties
   (--cat-color, --cat-light, --cat-mid) set at :root and updated by JS:
     - Vehicles     → blue   (#2563eb, light #e8f0fe, mid #93b8f5)
     - Real Estate  → green  (#16a34a, light #e7f8ee, mid #8fd9ab)
     - Jobs         → purple (#7c3aed, light #f1eafe, mid #c4a8f7)
     - Services     → orange (#ea580c, light #fff1e8, mid #f7b98a)
     - Merchandise  → pink   (#db2777, light #fde8f0, mid #f5a8c9)
     - Default/Review → slate (#475569, light #eef1f5, mid #b6c0cc)

3. Each step card: 5px colored gradient top band, numbered badge in a tinted
   circle, description in a left-bordered callout box.

4. Category cards on Step 0: large icon, name, short description, colored
   border on hover, responsive grid (2 columns mobile, 3+ desktop).

5. Style the "Listing preview" panel as a realistic ad card with rounded
   corners, shadow, an image area (placeholder icon, or the first uploaded
   photo with a semi-transparent photo-count badge in the corner), bold
   title, large colored price, and a category badge pill.

6. Style textareas' helper row: "Insert example" as a small pill-shaped
   outline button, the character counter in monospace turning red/bold at
   the limit, and the public/private visibility badges as small rounded
   pills (light blue for public, light pink for private) next to the field
   label. Style the contact-info warning as an amber callout box below the
   field.

7. Style file-field thumbnails as a wrap of small (about 96px) cards with the
   image (or a placeholder/error icon), filename, status text ("Uploading…",
   an error message, or "Preview only (prototype)"), and a small circular ✕
   remove button in the top-right corner.

8. Style the Review step's grouped summary with a colored left border
   matching the category color, "Edit" links as small underlined text
   buttons, visibility badges next to field labels, and a horizontal strip of
   small thumbnail images for any photo fields.

9. Style the guidelines panel as a collapsible amber/yellow warning callout.

10. Style the pricing tier cards (Basic/Featured/Premium) as selectable
    bordered cards with a green accent, a feature checklist, and a "Total due
    at publish" summary row.

Update adwizard.css (and adwizard.js where dynamic theme variable updates are
needed) accordingly.
```

---

## Step 4 — Classic ASP Host Page + Authentication Cookie Check

```text
This application will be hosted inside an existing Classic ASP (VBScript)
site. Create an ASP host page, post-ad.asp, that:

1. AUTHENTICATION CHECK
   Before any HTML output, check for an existing authentication cookie (e.g.
   "AuthToken"). Write a reusable `IsAuthenticated(authToken)` function with a
   TODO showing where to plug in the real validation call against the
   existing site's session/auth table.
   - If missing/invalid: Response.Redirect to
     "/login.asp?returnUrl=" & Server.URLEncode(Request.ServerVariables
     ("URL")), then Response.End.
   - If valid: retrieve UserID and DisplayName (stub with TODO + sample
     assignments).

2. SSO TOKEN FOR THE PHP BACKEND
   Classic ASP/VBScript has no native JSON support, so the browser-side JS
   talks directly to PHP endpoints (upload-photo.php, save-ad.php),
   authenticated via a shared SSO token. Write a `GetSSOToken(userID)`
   function: check Session("SSOToken") and return it if present and not
   expired, otherwise generate a new token (GUID + UserID + timestamp), store
   it in Session and in a shared SSOTokens table with an expiry. Include a
   TODO noting that production should use an HMAC-signed token shared with
   the PHP app instead of a DB lookup.

3. PAGE OUTPUT
   Output an HTML5 document that:
   - Includes the existing site's shared header/footer via
     <!-- #include virtual="/includes/header.asp" --> and
     <!-- #include virtual="/includes/footer.asp" --> (placeholders).
   - References adwizard.css and adwizard.js as external files.
   - Includes a <div id="adwizard-root"></div> mount point.
   - Emits a small inline <script> block setting:
     window.ADWIZARD_CONFIG = {
       userId: "<%= UserID %>",
       displayName: "<%= Server.HTMLEncode(DisplayName) %>",
       ssoToken: "<%= SSOToken %>",
       csrfToken: "<%= GeneratedCSRFToken %>",
       uploadEndpoint: "https://yourdomain.com/php/upload-photo.php",
       deleteEndpoint: "https://yourdomain.com/php/delete-photo.php",
       saveEndpoint: "https://yourdomain.com/php/save-ad.php"
     };
     (escape/encode all dynamic values appropriately for VBScript → JS
     output)

Output post-ad.asp.
```

---

## Step 5 — `upload-photo.php` (PHP 5.3, fixed legacy folders)

```text
Create a PHP 5.3-compatible JSON API endpoint, upload-photo.php, for AdWizard
photo uploads:

STORAGE — preserve this exact legacy layout (hard dependency, do not change):
  - Large image:  C:\cable\finditclassifieds_com\web\php\big\
  - Thumbnail:    C:\cable\finditclassifieds_com\web\php\thumbs\
  - Corresponding web URL prefixes: https://www.finditclassifieds.com/php/big/
    and https://www.finditclassifieds.com/php/thumbs/

FILE NAMING — preserve this exact legacy convention:
  <caller's IP address, dots and colons replaced with dashes>-<YYYYMMDD-HHMMSS>.jpg
  (always output as .jpg via imagejpeg(), regardless of input format)
  If two uploads from the same IP land in the same second, append -1, -2, etc.
  to avoid overwriting.

RESIZING — thumbnail width 100px (long edge, preserving aspect ratio); the
"big" image is 5x the thumbnail's dimensions. Use imagecopyresized().

PHP 5.3 COMPATIBILITY — use array() not [], no ??, no arrow functions, no
anonymous classes. imagecreatefrombmp() does not exist until PHP 7.2, so
include a PHP 5.3-compatible BMP decoder (standard byte-unpacking approach
reading the BMP file header, DIB header, palette, and pixel data row by row
into a GD true-color image via imagesetpixel(), handling 1/4/8/16/24-bit
BMPs).

REQUEST CONTRACT
  POST multipart/form-data
  Headers: X-SSO-Token, X-CSRF-Token
  Fields: photo (file), userId (string)

  Success (200): {"success":true,"fileName":"...","originalName":"...",
                  "thumbUrl":"...","bigUrl":"...","width":N,"height":N}
  Error (4xx/5xx): {"success":false,"error":"..."}

VALIDATION
  - POST only (405 otherwise).
  - validateSSOToken($token, $userId) and validateCsrfToken($token, $userId)
    — stub functions with TODOs for the real shared-session lookup, returning
    true for now.
  - getRequestHeader($name) helper with a $_SERVER['HTTP_...'] fallback for
    servers where getallheaders() is unavailable.
  - Reject if no file, upload error, size 0 or > 8MB, or extension not in
    .gif/.jpg/.jpeg/.png/.bmp.
  - Use getimagesize() to verify the file is actually one of
    IMAGETYPE_JPEG/PNG/GIF/BMP — never trust the extension or client-supplied
    MIME type alone.
  - On JPEG load, set ini_set('gd.jpeg_ignore_warning', 1) before
    imagecreatefromjpeg() to avoid a known GD warning that can blank some
    images.

Output upload-photo.php.
```

---

## Step 6 — `save-ad.php` (PHP 5.3, rate limiting, content screening)

```text
Create a PHP 5.3-compatible JSON API endpoint, save-ad.php, for AdWizard's
final "Submit Listing" step.

REQUEST CONTRACT
  POST application/json
  Headers: X-SSO-Token, X-CSRF-Token
  Body: {category, submittedAt, listingTier, userId, answers, website}

  Success (200): {"success":true,"adId":N,"status":"active"|"pending_review"}
  Error (4xx/5xx): {"success":false,"error":"..."}

VALIDATION ORDER
1. Method must be POST (405); Content-Type must include "application/json"
   (415).
2. json_decode the body; if the result is not an array/object, fail(400,
   "Invalid JSON body.").
3. Required top-level keys: category, submittedAt, answers, userId — fail
   (400) listing the missing key if any are absent. "answers" must be an
   array/object.
4. HONEYPOT CHECK (before auth): if trim($data['website']) is non-empty,
   fail(400, "Submission could not be processed.") — the same generic message
   as other validation failures, so the response doesn't reveal which check
   failed.
5. AUTH: validateSSOToken($ssoToken, $userId) (401 on failure) and
   validateCsrfToken($csrfToken, $userId) (403 on failure) — same stub
   pattern as upload-photo.php, sharing the same getRequestHeader() helper.
6. CATEGORY WHITELIST: category must be one of vehicles, real-estate, jobs,
   services, merchandise (400 otherwise).
7. PAYLOAD SIZE: json_encode($answers) (no JSON_UNESCAPED_UNICODE — that's
   PHP 5.4+) must be <= 500KB (413 otherwise).
8. submittedAt: strtotime() it; if invalid, fall back to the current time
   rather than rejecting.

DATABASE WORK (PDO, prepared statements)
1. RATE LIMIT: SELECT COUNT(*) FROM classified_ads WHERE user_id = ? AND
   submitted_at >= CURDATE(). If >= 5 (define as MAX_ADS_PER_DAY = 5,
   matching the legacy 5-ads-per-day limit), fail(429, "You have reached the
   limit of 5 listings per day. Please try again tomorrow.").

2. CONTENT SCREENING — replaces the legacy bolIsAdBad()/RequiresReview
   pattern (which computed a flag but never used it to gate anything; every
   ad was always inserted with the same hardcoded status). Here, the result
   DOES gate the saved status:
     - Recursively collect every string value from `answers` (skip nested
       objects that look like photo entries, i.e. anything with a fileName
       key) into one block of text.
     - isAdContentBad($text, $ip): returns true if the text contains any of a
       banned-phrases list (e.g. "wire transfer", "western union",
       "moneygram", "cash app only", "venmo only", "bitcoin only", "click
       here", "whatsapp me", "work from home", "guaranteed income"), OR
       contains more than 2 URLs/www. occurrences, OR is more than 70%
       uppercase letters (when it has >40 letters total). Include a TODO that
       this is a starting point and $ip could be cross-referenced against a
       BlockedIPs table.
     - status = isAdContentBad(...) ? 'pending_review' : 'active'.

3. INSERT into classified_ads (user_id, category, ad_data, listing_tier,
   status, submitted_at, ip_address, created_at) VALUES (?, ?, ?, ?, ?, ?, ?,
   NOW()), where ad_data = json_encode($answers) (again, no
   JSON_UNESCAPED_UNICODE for PHP 5.3). Use $pdo->lastInsertId() for the
   returned adId.

Wrap all DB operations in try/catch(PDOException), log via error_log(), and
return generic 500 errors without leaking DB details to the client.

Output save-ad.php.
```

---

## Step 7 — `classified_ads` Database Schema

```text
Generate the SQL schema for the classified_ads table used by save-ad.php:

CREATE TABLE classified_ads (
  id           INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  user_id      INT UNSIGNED NOT NULL,
  category     VARCHAR(50)  NOT NULL,
  ad_data      JSON         NOT NULL,        -- or LONGTEXT if MySQL < 5.7
  listing_tier VARCHAR(20)  NOT NULL DEFAULT 'basic',
  status       VARCHAR(20)  NOT NULL DEFAULT 'pending_review',
  ip_address   VARCHAR(45)  NOT NULL,
  submitted_at DATETIME     NOT NULL,
  created_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_user_id (user_id),
  INDEX idx_category (category),
  INDEX idx_status (status),
  INDEX idx_user_submitted (user_id, submitted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

Also document the status lifecycle as a table:
  - pending_review: set by save-ad.php when isAdContentBad() flags the
    submission — held back from public listings pending moderation.
  - active: set by save-ad.php when the content screen passes — live and
    publicly visible.
  - sold: set via a future edit-ad flow — contact info hidden from the public
    listing.
  - expired: set by a future cleanup job once a listing passes its tier's
    duration (Basic 14 days / Featured 30 days / Premium 60 days).
  - rejected: set by a future moderator action on a pending_review ad.

Output as a markdown file, classified_ads-schema.md, including a migration
ALTER TABLE statement for adding listing_tier, ip_address, and the composite
index to a table that was created without them.
```

---

## Step 8 — Category Persona Generation Template (for new categories)

```text
Create a new category persona file at personas/[slug].json conforming to
personas/category-schema.json, for the following ad category:

CATEGORY NAME: [e.g. "Pet Adoption"]
SLUG: [lowercase-kebab, e.g. "pets"]
ICON: [a single emoji]
DESCRIPTION: [1 sentence shown on the category card]

LISTING DEFAULTS: titleFieldId, priceFieldId (or "" if not applicable),
descriptionFieldId

GUIDELINES: prohibited (list), requiredDocs (list, or empty), extra (string)

STEPS: For each step, list its title, tagline, description, and every field
as: id | label | type | required? | options (if select/radio/checkbox) |
min/max (if number) | maxLength/exampleText/visibility (if textarea) |
maxFiles (if file) | helpText (if any).

Guidance:
  - Keep field counts reasonable — 4-8 fields per step, 3-5 steps total.
  - Reuse the existing "Contact Info" step pattern (contactName,
    contactPhone, contactEmail, preferredContact, plus a privateNotes
    textarea with maxLength 300 and visibility "private") as the final step
    unless the category has a reason to differ.
  - If the category benefits from photos, add a file field with maxFiles 3
    and helpText "Up to 3 photos. Images are resized automatically after
    upload."
  - The category's main description field should have maxLength 1000,
    visibility "public", and a realistic, multi-line exampleText.
  - Validate every field's `type` against category-schema.json's allowed
    values, and ensure every select/radio/checkbox field has a non-empty
    `options` array, before finalizing.
```

---

## Step 9 — README Generation (optional)

```text
Generate a README.md file for this repository covering: the overall
architecture (Classic ASP host page → AdWizard wizard → upload-photo.php /
save-ad.php), how a user moves through the flow from login to a saved
listing, how category personas work and the full field-property reference
(including maxLength, exampleText, visibility, maxFiles) with instructions
for adding a new category, the public-vs-private text model and the honeypot/
double-submit/rate-limit/content-screening anti-abuse measures and what each
one protects against, the classified_ads table and status lifecycle, the
upload-photo.php storage layout and naming convention, and the
window.ADWIZARD_CONFIG contract between post-ad.asp and adwizard.js
(including how uploadEndpoint/saveEndpoint being null switches the front end
into standalone prototype mode for local testing).
```
