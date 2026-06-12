# AdWizard — Persona-Driven Classified Ad Submission Prompts

This file contains a set of prompts for generating **AdWizard**, a prototype
classified-ads ad-submission experience. It reuses the core idea from
PromptArchitect — **loading a JSON "persona" file that customizes a multi-step
guided experience** — but repurposes it so that the persona defines an **ad
category** (Vehicles, Real Estate, Jobs, Services, Merchandise, etc.) and the
multi-step wizard becomes a **Q&A flow that gathers the details needed for that
specific kind of ad**.

The front end is the same HTML5 + Vanilla JavaScript + external CSS approach.
The back end integrates with an **existing Classic ASP application** (auth
cookie check) and uses a **PHP 5.3 endpoint** as a JSON-handling bridge to save
the finished ad into a database table as a JSON blob, since classic ASP/VBScript
has no native JSON support and PHP 5.3 does (`json_encode` / `json_decode`).

---

## How to use this file

1. Run **Prompt 1** to generate the core wizard (HTML/CSS/JS) with a category
   picker, persona loader, and a generic dynamic Q&A renderer.
2. Run **Prompt 2** to define the category-persona schema and generate the
   example category persona JSON files.
3. Run **Prompt 3** to apply the visual design pass.
4. Run **Prompt 4** to add the Classic ASP host page with the authentication
   cookie check.
5. Run **Prompt 5** to generate the PHP 5.3 JSON-save bridge endpoint and the
   database table definition.
6. Use the **Persona Generation Template** (Step 6) to add new ad categories
   later.

---

## Step 1 — Core Wizard Application (HTML + CSS + JS)

```text
You are a senior software developer with 10+ years building custom web
applications that are HTML5 and Vanilla JavaScript based.

Build a solution made up of a single HTML file plus a separate CSS file and a
separate JavaScript file that the HTML file references. Ensure the application
works with CORS rules by using external CSS/JS file references, and use
JavaScript event listeners on DOM elements for all interactivity (no inline
onclick attributes).

Build an interactive web application called "AdWizard" — a guided, multi-step
classified ad submission flow. The flow works like this:

STEP 0 — CHOOSE A CATEGORY
Show a grid of category cards (Vehicles, Real Estate, Jobs, Services,
Merchandise — use placeholder icons/emoji for now). Clicking a category card
loads a corresponding "category persona" JSON file (see Step 2 of this prompt
series) that defines every subsequent step of the wizard for that category.
Until a category is chosen, show only this step.

DYNAMIC STEPS 1..N — DRIVEN BY THE LOADED PERSONA JSON
Once a category persona is loaded, dynamically render one wizard "step card"
per entry in the persona's `steps` array. Each step has a title, a short
tagline/description, and a list of `fields`. Support these field types,
rendered with appropriate HTML5 inputs:
  - "text"      → <input type="text">
  - "textarea"  → <textarea>
  - "number"    → <input type="number"> (respect min/max if provided)
  - "select"    → <select> populated from the field's `options` array
  - "radio"     → a group of radio buttons from `options`
  - "checkbox"  → a group of checkboxes from `options` (multi-select)
  - "tel"       → <input type="tel">
  - "email"     → <input type="email">
  - "date"      → <input type="date">
  - "file"      → <input type="file" accept="image/*" multiple> for photo
                  uploads (for the prototype, just track file names/count in
                  state — do not implement actual upload handling yet)
Each field has: id, label, type, required (boolean), placeholder (optional),
helpText (optional), options (for select/radio/checkbox), and for "number"
fields optional min/max.

Maintain an `answers` object in JS state keyed by field id. As the user fills
in fields, update `answers` live via input/change event listeners.

FINAL STEP — REVIEW & SUBMIT
After the last persona-defined step, show a "Review & Submit" step that
renders a clean read-only summary of every answer the user provided, grouped
by the step it came from (use each step's title as a group heading). Include
an "Edit" link/button next to each group that jumps back to that step. At the
bottom, show a "Submit Listing" button.

NAVIGATION
A header with pill-shaped step indicators (Category → one pill per persona
step → Review) that reflect progress; pills for completed steps show a
checkmark and are clickable to jump back. Each step card has Next/Back
buttons. The category step has no Back button; the Review step's primary
button is "Submit Listing" instead of "Next".

RIGHT-HAND SIDEBAR (sticky, always visible once a category is chosen):
  - A "Listing preview" panel that renders a live mock classified-ad preview
    card (title, price, category badge, short description, photo-count
    placeholder) built from whatever `answers` map to common fields like
    title/price/description — update live as the user types.
  - A "Completion" panel with one dot per wizard step (category + each
    persona step + review) that fills in green once that step's required
    fields are complete, plus a progress bar and "X / N steps complete" label.
  - A "Listing options & estimated cost" panel — placeholder for now (will be
    fully built out in a later prompt) showing three listing tiers: Basic
    (Free), Featured, and Premium, with placeholder pricing.
  - A "Posting tips" panel with a short static bulleted list of tips for
    writing a good classified ad (clear photos, honest condition, fair price,
    responsive contact info).

A toast notification element at the bottom of the screen for "Listing
submitted" and validation error messages.

STATE / SUBMISSION
On "Submit Listing", assemble a single JSON object:
{
  "category": "<persona category slug>",
  "submittedAt": "<ISO 8601 timestamp>",
  "answers": { ...the answers object... }
}
For this step, just log this object to the console and show a success toast —
the actual save-to-server logic will be added in a later prompt (Step 5) which
will POST this exact JSON shape to a PHP endpoint.

Use semantic HTML5, a light theme, and make sure every interactive element has
an appropriate ARIA label where relevant. Output three files: adwizard.html,
adwizard.css, adwizard.js.
```

---

## Step 2 — Category Persona Schema + Example Category Files

```text
Add a category-persona loading system to AdWizard:

1. JSON SCHEMA: Create personas/category-schema.json (JSON Schema draft-07)
   describing the category persona file format:

   - meta: {
       name (required string — display name, e.g. "Vehicle for Sale"),
       slug (required string — URL/category-safe id, e.g. "vehicles"),
       description (required string),
       icon (string — an emoji used as the category card icon),
       version, author, tags (array of strings)
     }

   - listingDefaults: {
       titleFieldId (string — which field id represents the ad's headline),
       priceFieldId (string — which field id represents the ad's price, or ""
         if the category has no price, e.g. "Jobs"),
       descriptionFieldId (string — which field id is the main free-text
         description used in the preview card)
     }

   - guidelines: {
       prohibited (array of strings — things not allowed in this category's
         ads, shown to the user before they start),
       requiredDocs (array of strings — optional, e.g. "VIN" for vehicles, "
         Proof of ownership" for real estate),
       extra (string — any additional posting guidance shown to the user)
     }

   - steps: array of step objects, each:
     {
       id (string, unique within the persona),
       title (string),
       tagline (string — short subtitle),
       description (string — shown in the step's info callout),
       fields: array of field objects as defined in Step 1 of this prompt
         series (id, label, type, required, placeholder, helpText, options,
         min, max)
     }

   Document every field's allowed `type` values in the schema description:
   "text","textarea","number","select","radio","checkbox","tel","email","date","file".

2. UI: Each category card from Step 0 should, on click, fetch/load the
   matching personas/<slug>.json file (use the same drag-and-drop-or-click
   loader pattern as PromptArchitect for cases where the user wants to load a
   custom category file instead of picking a built-in card — include a "Load
   custom category" drop zone below the category grid that accepts a .json
   file and validates it against the schema before use).

3. JS LOADER LOGIC:
   - Validate the loaded JSON: meta.name, meta.slug, and meta.description are
     required; every step must have at least one field; every field's `type`
     must be one of the allowed values; every "select"/"radio"/"checkbox"
     field must have a non-empty `options` array. Show clear validation errors
     if any check fails.
   - On success: store the persona in JS state, dynamically render the
     wizard's step pills and step cards from `persona.steps`, show the
     `guidelines` (prohibited items, required docs, extra guidance) as a
     dismissible info panel before Step 1, and use `listingDefaults` to wire
     up the live "Listing preview" panel from Step 1 of this prompt series.

4. Create the following example category persona files in personas/:

   a) personas/vehicles.json — "Vehicle for Sale" (slug "vehicles", icon 🚗).
      listingDefaults: titleFieldId pointing to a "headline" field, priceFieldId
      to an "askingPrice" field, descriptionFieldId to a "description" field.
      guidelines.prohibited: ["Stolen vehicles","Vehicles without a valid
      title","Salvage vehicles not disclosed as such"]. guidelines.requiredDocs:
      ["VIN","Title status (Clean/Salvage/Rebuilt)"].
      Steps:
        - "Vehicle Details": headline (text, required), make (text, required),
          model (text, required), year (number, required, min 1950, max 2027),
          mileage (number, required, min 0), vin (text, required, helpText
          about where to find it), bodyType (select: Sedan, SUV, Truck, Coupe,
          Van, Motorcycle, Other)
        - "Condition & History": condition (radio: Excellent, Good, Fair,
          Needs Work, For Parts — required), titleStatus (select: Clean,
          Salvage, Rebuilt, Lien — required), accidentHistory (radio: Yes, No
          — required), features (checkbox: A/C, Heated Seats, Sunroof,
          Navigation, Backup Camera, Bluetooth, Leather Seats — optional),
          description (textarea, required, placeholder about describing
          condition honestly)
        - "Price & Photos": askingPrice (number, required, min 0), negotiable
          (radio: Yes, No — required), photos (file, required, helpText
          "Upload at least 3 photos")
        - "Contact Info": contactName (text, required), contactPhone (tel,
          required), contactEmail (email, required), preferredContact (radio:
          Phone, Email, Text — required), zipCode (text, required)

   b) personas/real-estate.json — "Real Estate / Rental" (slug "real-estate",
      icon 🏠). guidelines.prohibited: ["Discriminatory housing language
      (Fair Housing Act compliance required)","Properties not owned or
      authorized for listing by the poster"]. guidelines.requiredDocs:
      ["Proof of ownership or property management authorization"].
      Steps:
        - "Property Details": headline (text, required), listingType (radio:
          For Sale, For Rent — required), propertyType (select: House,
          Apartment, Condo, Townhouse, Land, Commercial — required), bedrooms
          (number, min 0), bathrooms (number, min 0), squareFootage (number,
          min 0)
        - "Location": address (text, required), city (text, required), state
          (text, required), zipCode (text, required)
        - "Description & Amenities": description (textarea, required),
          amenities (checkbox: Parking, Pool, Gym, Pet Friendly, In-Unit
          Laundry, Air Conditioning, Furnished — optional)
        - "Price & Availability": price (number, required, min 0),
          priceType (select: Total Price, Per Month, Per Night — required for
          rentals), availableDate (date, required)
        - "Contact Info": contactName (text, required), contactPhone (tel,
          required), contactEmail (email, required), preferredContact (radio:
          Phone, Email, Text — required)

   c) personas/jobs.json — "Job Listing" (slug "jobs", icon 💼).
      listingDefaults.priceFieldId should be "" (jobs don't have a price field
      in the traditional sense — use a salary field but don't treat it as the
      preview's "price"). guidelines.prohibited: ["Pyramid schemes or MLM
      recruitment","Jobs requiring upfront payment from applicants",
      "Discriminatory requirements unrelated to job function"].
      Steps:
        - "Job Details": jobTitle (text, required), companyName (text,
          required), employmentType (select: Full-time, Part-time, Contract,
          Temporary, Internship — required), workArrangement (radio: On-site,
          Remote, Hybrid — required)
        - "Compensation & Requirements": salaryMin (number, min 0), salaryMax
          (number, min 0), salaryPeriod (select: Per Hour, Per Year —
          required), requirements (textarea, required, placeholder about
          listing required skills/experience)
        - "Description": description (textarea, required, helpText about
          describing responsibilities and culture)
        - "Application Info": applyMethod (radio: Email, External Link, In
          Person — required), applyContact (text, required, helpText "Email
          address, URL, or address depending on method chosen"), zipCode
          (text, required)

   d) personas/services.json — "Service Provider" (slug "services", icon 🛠️).
      guidelines.prohibited: ["Services requiring licenses you do not hold
      (e.g. electrical, plumbing) without disclosure","Multi-level marketing
      opportunities disguised as services"].
      Steps:
        - "Service Details": headline (text, required), serviceCategory
          (select: Home Improvement, Cleaning, Lawn & Garden, Moving, Tutoring,
          Pet Care, Tech Support, Other — required), yearsExperience (number,
          min 0)
        - "Availability & Area": serviceArea (text, required, helpText
          "Cities or zip codes you serve"), availability (checkbox: Weekdays,
          Weekends, Evenings, On-call — optional)
        - "Pricing & Description": pricingModel (radio: Hourly Rate, Flat
          Rate, Free Estimate — required), rate (number, min 0), description
          (textarea, required)
        - "Contact Info": contactName (text, required), contactPhone (tel,
          required), contactEmail (email, required), preferredContact (radio:
          Phone, Email, Text — required)

   e) personas/merchandise.json — "General Merchandise" (slug "merchandise",
      icon 🛍️). guidelines.prohibited: ["Counterfeit goods","Recalled
      products","Weapons, ammunition, or hazardous materials","Live animals"].
      Steps:
        - "Item Details": headline (text, required), itemCategory (select:
          Electronics, Furniture, Clothing & Accessories, Toys & Games, Sports
          & Outdoors, Tools, Books & Media, Other — required), condition
          (radio: New, Like New, Good, Fair, For Parts — required)
        - "Description & Photos": description (textarea, required), photos
          (file, required, helpText "Upload at least 1 photo")
        - "Price": price (number, required, min 0), negotiable (radio: Yes,
          No — required)
        - "Contact Info": contactName (text, required), contactPhone (tel,
          optional), contactEmail (email, required), preferredContact (radio:
          Email, Phone — required), zipCode (text, required)

Validate every persona file against category-schema.json before finalizing —
every field's `type` must be one of the allowed values, and every
select/radio/checkbox field must have a populated `options` array.
```

---

## Step 3 — Visual Design Pass

```text
The AdWizard application looks plain. Update adwizard.css to make it more
colorful and improve usability:

1. Light theme: background #f4f6fb, card surfaces white and #f8f9fd, with a
   subtle 40px grid-line background pattern at low opacity.

2. Assign each category its own accent color, used for that category's card
   border/icon background on the Category step, and for the step-pill/badge/
   focus-ring colors once that category's persona is loaded:
     - Vehicles     → blue   (#2563eb, light #e8f0fe, mid #93b8f5)
     - Real Estate  → green  (#16a34a, light #e7f8ee, mid #8fd9ab)
     - Jobs         → purple (#7c3aed, light #f1eafe, mid #c4a8f7)
     - Services     → orange (#ea580c, light #fff1e8, mid #f7b98a)
     - Merchandise  → pink   (#db2777, light #fde8f0, mid #f5a8c9)
     - Review step  → slate  (#475569, light #eef1f5, mid #b6c0cc)

3. Use CSS custom properties (--cat-color, --cat-light, --cat-mid) set at
   :root and updated by JS whenever a category persona is loaded, so the
   sidebar and step cards adopt the active category's color.

4. Each step card: 5px colored gradient top band, numbered badge in a tinted
   circle, and the step description in a left-bordered callout box.

5. Category cards on Step 0: large icon, name, short description, and a
   colored border that fills in fully on hover, in a responsive grid (2
   columns on mobile, 3+ on desktop).

6. Style the "Listing preview" panel as a realistic classified-ad card
   (rounded corners, shadow, placeholder image area, bold title, price in
   large colored text, category badge pill).

7. Style the Review step's grouped summary with each group in a bordered card
   with a colored left border matching the category color, and "Edit" links
   styled as small text buttons in the category color.

8. Style the guidelines panel (prohibited items / required docs) with a
   warning-style amber/yellow callout box, shown collapsible via
   <details>/<summary>.

Update adwizard.css (and adwizard.js where dynamic --cat-color/--cat-light/
--cat-mid updates are needed) accordingly. Do not change the HTML structure
except where a wrapper is needed for the category grid or guidelines panel.
```

---

## Step 4 — Classic ASP Host Page + Authentication Cookie Check

```text
This application will be hosted inside an existing Classic ASP (VBScript)
site. Create an ASP host page, post-ad.asp, that:

1. AUTHENTICATION CHECK
   At the very top of the page (before any HTML output), check for an
   existing authentication cookie used elsewhere in the site — assume it is
   named "AuthToken" and its value is a session/user identifier that can be
   looked up in a Sessions table (or validated however the existing site's
   auth logic works — write this as a reusable function
   `IsAuthenticated(authToken)` that you can wire into the existing
   authentication module, with a TODO comment showing where to plug in the
   real validation call).

   - If the cookie is missing or invalid, redirect (Response.Redirect) to
     "/login.asp?returnUrl=" & Server.URLEncode(Request.ServerVariables
     ("URL")), and call Response.End.
   - If valid, retrieve the authenticated user's UserID and DisplayName (from
     session or a DB lookup — stub this with a TODO and sample variable
     assignments) for use later in the page.

2. SSO TOKEN FOR THE PHP BRIDGE
   This site also runs a PHP 5.3 application that exposes a JSON-saving
   endpoint (built in Step 5 of this prompt series). Classic ASP/VBScript has
   no native JSON support, so the browser-side JS will POST the finished ad
   JSON directly to the PHP endpoint, authenticated via a shared SSO token.

   Generate (or retrieve, if one already exists in session) an SSO token for
   the current authenticated user — write a `GetSSOToken(userID)` function
   stub that: (a) checks Session("SSOToken") and returns it if present and not
   expired, or (b) otherwise generates a new token (for the prototype, a
   simple value such as a GUID via Server.CreateObject
   ("Scriptlet.TypeLib").Guid combined with the UserID and a timestamp,
   stored in Session and also written to a shared SSOTokens table with an
   expiry, for the PHP endpoint to validate against) — include a TODO comment
   explaining that in production this should be a signed token (e.g. HMAC)
   shared via a common secret between the ASP and PHP applications.

3. PAGE OUTPUT
   Output a standard HTML5 document that:
   - Includes the existing site's shared header/footer via Server-Side
     Includes (use placeholder includes: <!-- #include
     virtual="/includes/header.asp" --> and
     <!-- #include virtual="/includes/footer.asp" -->).
   - References adwizard.css and adwizard.js as external files (the same
     ones built in Steps 1-3).
   - Includes a <div id="adwizard-root"></div> mount point for the
     application (or the application's existing root markup — adapt as
     needed).
   - Emits a small inline <script> block (this is configuration data, not
     application logic, so an inline block is acceptable here) that sets:
     window.ADWIZARD_CONFIG = {
       userId: "<%= UserID %>",
       displayName: "<%= Server.HTMLEncode(DisplayName) %>",
       ssoToken: "<%= SSOToken %>",
       saveEndpoint: "https://yourdomain.com/api/save-ad.php",
       csrfToken: "<%= GeneratedCSRFToken %>"
     };
     (escape/encode all dynamic values appropriately for VBScript → JS output)

4. Update adwizard.js so that, on "Submit Listing", instead of just logging
   to the console, it:
   - Builds the same JSON shape as before: { category, submittedAt, answers }
   - Adds userId and csrfToken from window.ADWIZARD_CONFIG to the payload
   - POSTs it as JSON (fetch, Content-Type: application/json, header
     "X-SSO-Token": window.ADWIZARD_CONFIG.ssoToken) to
     window.ADWIZARD_CONFIG.saveEndpoint
   - On a successful JSON response ({success:true, adId: N}), show a success
     toast including the returned adId and disable the Submit button
   - On failure, show an error toast with the server's error message and
     re-enable the Submit button so the user can retry

Output post-ad.asp, and the updated adwizard.js.
```

---

## Step 5 — PHP 5.3 JSON-Save Bridge Endpoint

```text
Create a PHP 5.3-compatible endpoint, save-ad.php, that acts as a JSON-saving
bridge for the Classic ASP application (which lacks native JSON support). PHP
5.3 has json_encode/json_decode built in since 5.2, so this endpoint receives
the ad submission from the browser, validates it, and stores it as JSON in a
database column.

1. REQUEST HANDLING
   - Only accept POST requests with Content-Type: application/json. Reject
     anything else with HTTP 405.
   - Read the raw request body and decode it with json_decode($input, true).
     If decoding fails (json_last_error() !== JSON_ERROR_NONE) or required
     top-level keys (category, submittedAt, answers, userId, csrfToken) are
     missing, respond with HTTP 400 and {"success":false,"error":"..."}.

2. SSO TOKEN VALIDATION
   - Read the X-SSO-Token header (getallheaders() or
     $_SERVER['HTTP_X_SSO_TOKEN']).
   - Write a function validateSSOToken($token, $userId) that, for the
     prototype, looks up the token in an SSOTokens table (shared with the ASP
     app) via PDO/mysqli — check the token exists, matches the given userId,
     and has not expired. Include a TODO noting that in production this should
     verify an HMAC-signed token using a secret shared with the ASP app rather
     than a DB lookup, for performance.
   - If validation fails, respond with HTTP 401 and
     {"success":false,"error":"Invalid or expired session"}.

3. CSRF CHECK
   - Write a simple validateCsrfToken($token, $userId) stub function with a
     TODO for wiring into the existing site's CSRF mechanism. If invalid,
     respond with HTTP 403.

4. VALIDATION OF THE AD PAYLOAD
   - Confirm `category` is one of the known category slugs (vehicles,
     real-estate, jobs, services, merchandise) — reject unknown categories
     with HTTP 400.
   - Confirm `answers` is a non-empty associative array/object.
   - Sanitize all string values in `answers` for storage (trim, strip null
     bytes) — do NOT html-encode at this stage since this is raw data
     storage, but do guard against absurdly large payloads (reject if the
     json_encode'd size of `answers` exceeds e.g. 500KB, HTTP 413).

5. DATABASE SAVE
   Provide the SQL to create the table (MySQL syntax, since this is the most
   common pairing with PHP 5.3 era Classic ASP migrations — adjust types as
   needed):

   CREATE TABLE classified_ads (
     id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
     user_id INT UNSIGNED NOT NULL,
     category VARCHAR(50) NOT NULL,
     ad_data JSON NOT NULL,        -- or LONGTEXT if MySQL < 5.7
     status VARCHAR(20) NOT NULL DEFAULT 'pending_review',
     submitted_at DATETIME NOT NULL,
     created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
     INDEX idx_user_id (user_id),
     INDEX idx_category (category),
     INDEX idx_status (status)
   ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

   In the PHP code:
   - Connect via PDO with a prepared statement (no string concatenation of
     values into SQL).
   - Re-encode the validated `answers` object with json_encode($answers,
     JSON_UNESCAPED_UNICODE) and insert it into the `ad_data` column, along
     with user_id, category, submitted_at (from the payload's submittedAt,
     validated as a parseable date), and status = 'pending_review'.
   - On success, respond with HTTP 201 and
     {"success":true,"adId": <insert id>}.
   - On DB error, log the error server-side (error_log) and respond with HTTP
     500 and {"success":false,"error":"Could not save listing. Please try
     again."} — do not leak DB error details to the client.

6. EXTRACTION HELPER (for later use)
   As a bonus, also provide a short second script, export-ads.php, that
   demonstrates reading rows back out: SELECT id, category, ad_data,
   submitted_at FROM classified_ads WHERE status = ?, then
   json_decode($row['ad_data'], true) on each row, and print a simple HTML
   table showing category, submitted_at, and a few key fields pulled out of
   the decoded answers array (e.g. headline/title and price if present) —
   illustrating how downstream reporting can consume the stored JSON.

Write defensive PHP 5.3-compatible code: avoid features introduced after 5.3
(no anonymous classes, no null coalescing operator ??, no arrow functions —
use isset()/empty() checks instead). Output save-ad.php and export-ads.php.
```

---

## Step 6 — Category Persona Generation Template

Use this template to add a new ad category later.

```text
Create a new category persona file at personas/[slug].json conforming to
personas/category-schema.json, for the following ad category:

CATEGORY NAME: [e.g. "Pet Adoption"]
SLUG: [lowercase-kebab, e.g. "pets"]
ICON: [a single emoji]
DESCRIPTION: [1 sentence shown on the category card]

LISTING DEFAULTS:
  titleFieldId: [which field id is the ad's headline]
  priceFieldId: [which field id is the price, or "" if not applicable]
  descriptionFieldId: [which field id is the main description]

GUIDELINES:
  prohibited: [list of things not allowed in this category]
  requiredDocs: [list of documents/info required, or empty list]
  extra: [any additional posting guidance]

STEPS:
[For each step, list: step title, tagline, description, and every field as
  id | label | type | required? | options (if select/radio/checkbox) |
  min/max (if number) | helpText (if any)]

Keep field counts reasonable — 4-8 fields per step, 3-5 steps total. Reuse the
existing "Contact Info" step pattern (contactName, contactPhone, contactEmail,
preferredContact) as the final step unless the category has a reason to
differ. Validate every field's `type` against category-schema.json's allowed
values, and ensure every select/radio/checkbox field has a non-empty `options`
array, before finalizing.
```

---

## Reference — Files Produced

```
adwizard/
├── adwizard.html
├── adwizard.css
├── adwizard.js
├── post-ad.asp                 (Classic ASP host page + auth cookie check)
├── save-ad.php                 (PHP 5.3 JSON-save bridge endpoint)
├── export-ads.php              (PHP 5.3 example: reading JSON ad data back out)
└── personas/
    ├── category-schema.json
    ├── vehicles.json
    ├── real-estate.json
    ├── jobs.json
    ├── services.json
    └── merchandise.json
```

### Data flow summary

1. User authenticates via the existing Classic ASP login flow (sets
   `AuthToken` cookie).
2. `post-ad.asp` checks `AuthToken`, retrieves/generates an SSO token, and
   serves the AdWizard HTML/CSS/JS with a small config block (user id, SSO
   token, save endpoint URL, CSRF token).
3. The user picks a category → AdWizard loads `personas/<slug>.json` and
   dynamically renders that category's multi-step Q&A.
4. On submit, AdWizard POSTs `{ category, submittedAt, answers, userId,
   csrfToken }` as JSON to `save-ad.php`, with the SSO token in the
   `X-SSO-Token` header.
5. `save-ad.php` validates the SSO token and CSRF token, validates the
   payload, `json_encode()`s the answers, and inserts a row into
   `classified_ads.ad_data` (a JSON column).
6. `export-ads.php` demonstrates reading rows back out with `json_decode()`
   for reporting/admin use.

---

## Step 7 — README Generation (optional)

```text
Generate a README.md file for this repository that explains: the overall
architecture (Classic ASP host page + HTML5/Vanilla JS wizard + PHP 5.3 JSON
bridge), how a user moves through the flow from login to submission, how
category personas work and how to add a new one (with the full schema
reference and allowed field types), the database table structure for
classified_ads, the SSO token hand-off between ASP and PHP and what would need
to change to make it production-ready (HMAC-signed tokens instead of DB
lookups), and notes on the PHP 5.3 compatibility constraints applied
throughout save-ad.php and export-ads.php.
```
