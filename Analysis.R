library(shiny)
library(ggplot2)

library(dplyr)


library(readr)
library(lubridate)
library(tidyr)

# =====================================================
# EMOTION -> ENGAGEMENT SCORE MAPPING
# =====================================================

emotion_weights <- c(
  happy = 1.0,
  surprise = 0.8,
  neutral = 0.5,
  sad = 0.3,
  fear = 0.2,
  angry = 0.1,
  disgust = 0.0
)

# =====================================================
# USER CREDENTIALS
# =====================================================

valid_users <- list(
  list(username = "admin",    password = "123",   role = "Administrator", name = "Admin User"),
  list(username = "aaay",     password = "123",   role = "Professor",     name = "Dr. Mohamed"),
  list(username = "ta",       password = "ta",     role = "Teaching Assistant", name = "T.A. Sara")
)

# =====================================================
# LOAD DATA
# =====================================================

load_emotion_data <- function() {
  if (!file.exists("log.csv")) {
    return(data.frame(
      student_id = character(),
      timestamp = character(),
      emotion = character(),
      confidence = numeric(),
      lecture_id = character(),
      time = as.POSIXct(character()),
      confidence_norm = numeric(),
      engagement_score = numeric(),
      time_bin = as.POSIXct(character()),
      stringsAsFactors = FALSE
    ))
  }
  data <- read_csv("log.csv", show_col_types = FALSE)
  if ("Lecture_id" %in% names(data)) {
    data <- data %>% rename(lecture_id = Lecture_id)
  }
  data$time <- ymd_hms(data$timestamp)
  data$confidence_norm <- data$confidence / 100
  data$engagement_score <- emotion_weights[data$emotion] * data$confidence_norm
  data$time_bin <- floor_date(data$time, "minute")
  data$lecture_id <- as.factor(data$lecture_id)
  data$student_id <- as.factor(data$student_id)
  return(data)
}

load_attendance_data <- function() {
  if (!file.exists("attendance.csv")) {
    return(data.frame(
      student_id = character(),
      timestamp = as.POSIXct(character()),
      lecture_id = character(),
      stringsAsFactors = FALSE
    ))
  }
  att <- read_csv("attendance.csv", show_col_types = FALSE)
  names(att) <- tolower(names(att))
  att$timestamp <- ymd_hms(att$timestamp)
  att$lecture_id <- as.factor(att$lecture_id)
  att$student_id <- as.factor(att$student_id)
  return(att)
}

# =====================================================
# THEME & CUSTOM CSS/JS
# =====================================================

custom_css <- "
@import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600&family=Space+Grotesk:wght@400;500;600;700&display=swap');

:root {
  --bg-deep:        #0d1117;
  --bg-card:        #161b22;
  --bg-card2:       #1c2330;
  --bg-sidebar:     #111318;
  --border:         #2a3140;
  --accent:         #4f9cf9;
  --accent-glow:    rgba(79,156,249,0.18);
  --accent2:        #38d9a9;
  --accent2-glow:   rgba(56,217,169,0.15);
  --text-primary:   #e6edf3;
  --text-secondary: #8b949e;
  --text-muted:     #484f58;
  --success:        #3fb950;
  --danger:         #f85149;
  --warning:        #d29922;
  --radius:         12px;
  --radius-sm:      8px;
  --shadow:         0 4px 24px rgba(0,0,0,0.45);
  --shadow-sm:      0 2px 10px rgba(0,0,0,0.3);
}

/* ── GLOBAL ── */
* { box-sizing: border-box; }

html, body {
  margin: 0; padding: 0;
  background: var(--bg-deep);
  color: var(--text-primary);
  font-family: 'DM Sans', sans-serif;
  font-size: 14px;
  min-height: 100vh;
}

/* scrollbar */
::-webkit-scrollbar { width: 6px; }
::-webkit-scrollbar-track { background: var(--bg-deep); }
::-webkit-scrollbar-thumb { background: var(--border); border-radius: 3px; }

/* ── LOGIN OVERLAY ── */
#login_overlay {
  position: fixed; inset: 0; z-index: 9999;
  display: flex; align-items: center; justify-content: center;
  background: radial-gradient(ellipse at 60% 40%, #1a2744 0%, #0d1117 70%);
  animation: bgPulse 8s ease-in-out infinite alternate;
}

@keyframes bgPulse {
  0%   { background: radial-gradient(ellipse at 60% 40%, #1a2744 0%, #0d1117 70%); }
  100% { background: radial-gradient(ellipse at 40% 60%, #132230 0%, #0d1117 70%); }
}

/* Floating dots background */
#login_overlay::before {
  content: '';
  position: absolute; inset: 0;
  background-image:
    radial-gradient(circle, rgba(79,156,249,0.12) 1px, transparent 1px),
    radial-gradient(circle, rgba(56,217,169,0.08) 1px, transparent 1px);
  background-size: 60px 60px, 90px 90px;
  background-position: 0 0, 30px 30px;
  animation: drift 20s linear infinite;
}
@keyframes drift { 0% { background-position: 0 0, 30px 30px; } 100% { background-position: 60px 60px, 90px 90px; } }

/* Login card */
.login-card {
  position: relative; z-index: 2;
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 20px;
  padding: 48px 44px;
  width: 420px;
  box-shadow: var(--shadow), 0 0 60px rgba(79,156,249,0.08);
  animation: cardIn 0.7s cubic-bezier(0.34,1.56,0.64,1) both;
}

@keyframes cardIn {
  from { opacity: 0; transform: translateY(40px) scale(0.95); }
  to   { opacity: 1; transform: translateY(0) scale(1); }
}

.login-logo {
  text-align: center; margin-bottom: 32px;
}
.login-logo .logo-icon {
  width: 64px; height: 64px; margin: 0 auto 16px;
  background: linear-gradient(135deg, var(--accent), var(--accent2));
  border-radius: 18px;
  display: flex; align-items: center; justify-content: center;
  font-size: 28px;
  box-shadow: 0 8px 32px rgba(79,156,249,0.3);
  animation: logoFloat 3s ease-in-out infinite;
}
@keyframes logoFloat {
  0%,100% { transform: translateY(0); }
  50%      { transform: translateY(-6px); }
}
.login-logo h2 {
  font-family: 'Space Grotesk', sans-serif;
  font-size: 22px; font-weight: 700;
  color: var(--text-primary);
  margin: 0 0 4px;
}
.login-logo p {
  color: var(--text-secondary); font-size: 13px; margin: 0;
}

.login-field { margin-bottom: 18px; }
.login-field label {
  display: block; font-size: 12px; font-weight: 600;
  color: var(--text-secondary); letter-spacing: 0.05em;
  text-transform: uppercase; margin-bottom: 7px;
}
.login-field input {
  width: 100%; padding: 12px 16px;
  background: var(--bg-deep); border: 1px solid var(--border);
  border-radius: var(--radius-sm); color: var(--text-primary);
  font-family: 'DM Sans', sans-serif; font-size: 14px;
  outline: none; transition: border-color 0.25s, box-shadow 0.25s;
}
.login-field input:focus {
  border-color: var(--accent);
  box-shadow: 0 0 0 3px var(--accent-glow);
}
.login-field input::placeholder { color: var(--text-muted); }

.login-btn {
  width: 100%; padding: 13px;
  background: linear-gradient(135deg, #3b82f6, #1d6fd8);
  border: none; border-radius: var(--radius-sm);
  color: #fff; font-family: 'Space Grotesk', sans-serif;
  font-size: 15px; font-weight: 600; cursor: pointer;
  transition: transform 0.15s, box-shadow 0.25s, opacity 0.2s;
  box-shadow: 0 4px 20px rgba(59,130,246,0.4);
  margin-top: 6px;
}
.login-btn:hover  { transform: translateY(-2px); box-shadow: 0 8px 28px rgba(59,130,246,0.5); }
.login-btn:active { transform: translateY(0); }

.login-error {
  background: rgba(248,81,73,0.12); border: 1px solid rgba(248,81,73,0.35);
  color: #f85149; border-radius: var(--radius-sm);
  padding: 10px 14px; font-size: 13px; margin-top: 14px;
  animation: shake 0.4s ease;
  display: none;
}
@keyframes shake {
  0%,100% { transform: translateX(0); }
  25%      { transform: translateX(-8px); }
  75%      { transform: translateX(8px); }
}
.login-error.show { display: block; }

/* ── MAIN APP FADE-IN ── */
#main_app {
  animation: appFadeIn 0.8s ease both;
}
@keyframes appFadeIn {
  from { opacity: 0; transform: translateY(12px); }
  to   { opacity: 1; transform: translateY(0); }
}

/* ── TOP NAVBAR ── */
.top-navbar {
  background: var(--bg-card);
  border-bottom: 1px solid var(--border);
  padding: 0 28px;
  height: 60px;
  display: flex; align-items: center; justify-content: space-between;
  position: sticky; top: 0; z-index: 100;
  backdrop-filter: blur(12px);
}
.navbar-brand {
  font-family: 'Space Grotesk', sans-serif;
  font-size: 17px; font-weight: 700; color: var(--text-primary);
  display: flex; align-items: center; gap: 10px;
}
.navbar-brand .brand-dot {
  width: 8px; height: 8px; border-radius: 50%;
  background: var(--accent2);
  box-shadow: 0 0 8px var(--accent2);
  animation: blink 2s ease-in-out infinite;
}
@keyframes blink { 0%,100% { opacity:1; } 50% { opacity:0.3; } }

.navbar-user {
  display: flex; align-items: center; gap: 12px;
}
.user-badge {
  background: var(--bg-card2); border: 1px solid var(--border);
  border-radius: 40px; padding: 6px 14px 6px 8px;
  display: flex; align-items: center; gap: 8px;
}
.user-avatar {
  width: 30px; height: 30px; border-radius: 50%;
  background: linear-gradient(135deg, var(--accent), var(--accent2));
  display: flex; align-items: center; justify-content: center;
  font-size: 13px; font-weight: 700; color: #fff;
}
.user-info .user-name { font-size: 13px; font-weight: 600; color: var(--text-primary); line-height: 1.2; }
.user-info .user-role { font-size: 11px; color: var(--text-secondary); }

.logout-btn {
  background: rgba(248,81,73,0.1); border: 1px solid rgba(248,81,73,0.3);
  color: var(--danger); padding: 7px 14px; border-radius: var(--radius-sm);
  cursor: pointer; font-size: 13px; font-weight: 500;
  transition: all 0.2s; font-family: 'DM Sans', sans-serif;
}
.logout-btn:hover { background: rgba(248,81,73,0.2); }

/* ── LAYOUT ── */
.app-layout {
  display: flex; height: calc(100vh - 60px);
}

/* ── SIDEBAR ── */
.app-sidebar {
  width: 260px; min-width: 260px;
  background: var(--bg-sidebar);
  border-right: 1px solid var(--border);
  padding: 20px 16px;
  overflow-y: auto;
}

.sidebar-section-label {
  font-size: 10px; font-weight: 700; letter-spacing: 0.1em;
  text-transform: uppercase; color: var(--text-muted);
  padding: 0 8px; margin: 20px 0 8px;
}

.sidebar-select label {
  font-size: 11px; color: var(--text-secondary); font-weight: 600;
  text-transform: uppercase; letter-spacing: 0.05em;
  display: block; margin-bottom: 6px; padding: 0 8px;
}
.sidebar-select select,
.app-sidebar .selectize-input,
.app-sidebar select {
  width: 100%; padding: 9px 12px;
  background: var(--bg-card) !important;
  border: 1px solid var(--border) !important;
  border-radius: var(--radius-sm) !important;
  color: var(--text-primary) !important;
  font-family: 'DM Sans', sans-serif;
  font-size: 13px; outline: none;
}

.app-sidebar .irs--shiny .irs-line { background: var(--border); }
.app-sidebar .irs--shiny .irs-bar  { background: var(--accent); border-color: var(--accent); }
.app-sidebar .irs--shiny .irs-handle { background: var(--accent); border-color: var(--accent); }
.app-sidebar .irs--shiny .irs-from,
.app-sidebar .irs--shiny .irs-to,
.app-sidebar .irs--shiny .irs-single { background: var(--accent); }
.app-sidebar .irs--shiny .irs-min,
.app-sidebar .irs--shiny .irs-max { background: var(--bg-card2); color: var(--text-muted); }

/* stat cards in sidebar */
.stat-card {
  background: var(--bg-card); border: 1px solid var(--border);
  border-radius: var(--radius-sm); padding: 14px 16px; margin-bottom: 10px;
  transition: border-color 0.2s;
}
.stat-card:hover { border-color: var(--accent); }
.stat-card .stat-label { font-size: 11px; color: var(--text-secondary); margin-bottom: 4px; }
.stat-card .stat-value {
  font-family: 'Space Grotesk', sans-serif;
  font-size: 22px; font-weight: 700; color: var(--text-primary);
}
.stat-card .stat-value.green { color: var(--success); }
.stat-card .stat-value.blue  { color: var(--accent); }

/* ── MAIN CONTENT ── */
.app-main {
  flex: 1; overflow-y: auto; background: var(--bg-deep);
  padding: 24px 28px;
}

/* ── SHINY OVERRIDES ── */
.shiny-bound-output { color: var(--text-primary); }

.tabbable { height: 100%; }
.nav-tabs {
  border-bottom: 1px solid var(--border) !important;
  margin-bottom: 20px;
}
.nav-tabs > li > a {
  background: transparent !important;
  border: none !important; border-bottom: 2px solid transparent !important;
  color: var(--text-secondary) !important;
  font-family: 'Space Grotesk', sans-serif !important;
  font-size: 13px !important; font-weight: 500 !important;
  padding: 10px 18px !important; border-radius: 0 !important;
  transition: all 0.2s !important;
}
.nav-tabs > li > a:hover { color: var(--text-primary) !important; }
.nav-tabs > li.active > a {
  color: var(--accent) !important;
  border-bottom: 2px solid var(--accent) !important;
}

/* plot containers */
.plot-card {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 20px; margin-bottom: 20px;
  box-shadow: var(--shadow-sm);
  transition: border-color 0.25s, box-shadow 0.25s;
}
.plot-card:hover {
  border-color: rgba(79,156,249,0.35);
  box-shadow: 0 4px 28px rgba(79,156,249,0.08);
}
.plot-card-title {
  font-family: 'Space Grotesk', sans-serif;
  font-size: 14px; font-weight: 600;
  color: var(--text-secondary); margin-bottom: 14px;
  display: flex; align-items: center; gap: 8px;
}
.plot-card-title .dot {
  width: 6px; height: 6px; border-radius: 50%;
  background: var(--accent);
}

/* table */
.shiny-html-output table,
.app-main table {
  width: 100%; border-collapse: collapse;
  font-size: 13px; color: var(--text-primary);
}
.shiny-html-output th, .app-main th {
  background: var(--bg-card2) !important;
  color: var(--text-secondary) !important;
  font-weight: 600 !important; font-size: 11px !important;
  text-transform: uppercase; letter-spacing: 0.05em;
  padding: 10px 14px !important;
  border-bottom: 1px solid var(--border) !important;
}
.shiny-html-output td, .app-main td {
  padding: 10px 14px !important;
  border-bottom: 1px solid rgba(42,49,64,0.5) !important;
  color: var(--text-primary) !important;
}
.shiny-html-output tr:hover td, .app-main tr:hover td {
  background: var(--bg-card2) !important;
}

/* verbatim */
pre.shiny-text-output {
  background: var(--bg-deep) !important;
  border: 1px solid var(--border) !important;
  border-radius: var(--radius-sm) !important;
  color: var(--accent2) !important;
  font-size: 12px !important; padding: 12px !important;
}

/* checkboxes */
.checkbox label { color: var(--text-secondary) !important; font-size: 13px !important; }
.checkbox input[type=checkbox] { accent-color: var(--accent); }

/* slider label */
.control-label { color: var(--text-secondary) !important; font-size: 12px !important; font-weight: 600 !important; }

/* selectize */
.selectize-dropdown {
  background: var(--bg-card2) !important;
  border: 1px solid var(--border) !important;
  border-radius: var(--radius-sm) !important;
  color: var(--text-primary) !important;
}
.selectize-dropdown .option:hover,
.selectize-dropdown .option.active { background: var(--accent-glow) !important; }

/* camera */
#live_cam { border-radius: var(--radius); border: 1px solid var(--border) !important; }

/* attendance grid */
.att-badge {
  display: inline-block; padding: 3px 10px; border-radius: 20px;
  font-size: 11px; font-weight: 600;
}
.att-badge.present { background: rgba(63,185,80,0.15); color: var(--success); }
.att-badge.absent  { background: rgba(248,81,73,0.12); color: var(--danger); }

/* fluidRow gap */
.row { margin-left: -10px !important; margin-right: -10px !important; }
.col-sm-6, .col-sm-12 { padding-left: 10px !important; padding-right: 10px !important; }

/* hr */
hr { border-color: var(--border) !important; margin: 18px 0 !important; }

/* section heading */
h3 {
  font-family: 'Space Grotesk', sans-serif;
  font-size: 18px; font-weight: 700;
  color: var(--text-primary); margin: 0 0 20px;
  border-bottom: 1px solid var(--border); padding-bottom: 12px;
}
h4 {
  font-family: 'Space Grotesk', sans-serif;
  font-size: 14px; font-weight: 600;
  color: var(--text-secondary); margin: 0 0 12px;
}

/* loading spinner */
.shiny-spinner-output-container .shiny-spinner { border-top-color: var(--accent) !important; }

/* ── PLOT BACKGROUND ── */
/* ggplot2 themed via R */
"

custom_js <- "
$(document).ready(function() {

  // LOGIN LOGIC
  $('#do_login').on('click', function() {
    loginAttempt();
  });
  $('#login_pass').on('keypress', function(e) {
    if (e.which === 13) loginAttempt();
  });
  $('#login_user').on('keypress', function(e) {
    if (e.which === 13) $('#login_pass').focus();
  });

  function loginAttempt() {
    Shiny.setInputValue('login_attempt', {
      user: $('#login_user').val(),
      pass: $('#login_pass').val()
    }, {priority: 'event'});
  }

  // LOGOUT LOGIC
  $(document).on('click', '#logout_btn', function() {
    Shiny.setInputValue('logout_clicked', Math.random(), {priority: 'event'});
  });

  // LIVE CAMERA
  Shiny.addCustomMessageHandler('updateImage', function(message) {
    document.getElementById('live_cam').src = message.url;
  });

  // SHOW/HIDE app vs overlay
  Shiny.addCustomMessageHandler('showApp', function(msg) {
    if (msg.show) {
      $('#login_overlay').fadeOut(600);
      $('#main_app').fadeIn(400);
    } else {
      $('#login_overlay').fadeIn(400);
      $('#main_app').hide();
    }
  });

  Shiny.addCustomMessageHandler('loginError', function(msg) {
    var el = $('#login_error_msg');
    el.text(msg.text).addClass('show');
    setTimeout(function(){ el.removeClass('show'); }, 3000);
  });

  Shiny.addCustomMessageHandler('updateUserBadge', function(msg) {
    $('#user_name_display').text(msg.name);
    $('#user_role_display').text(msg.role);
    $('#user_avatar_letter').text(msg.letter);
  });
});
"

# ggplot2 dark theme
dark_theme <- function() {
  theme_minimal(base_family = "sans") +
    theme(
      plot.background    = element_rect(fill = "#161b22", color = NA),
      panel.background   = element_rect(fill = "#161b22", color = NA),
      panel.grid.major   = element_line(color = "#2a3140", linewidth = 0.4),
      panel.grid.minor   = element_blank(),
      axis.text          = element_text(color = "#8b949e", size = 11),
      axis.title         = element_text(color = "#8b949e", size = 11),
      plot.title         = element_text(color = "#e6edf3", size = 13, face = "bold", margin = margin(b=8)),
      plot.subtitle      = element_text(color = "#8b949e", size = 11),
      legend.background  = element_rect(fill = "#1c2330", color = NA),
      legend.text        = element_text(color = "#8b949e", size = 10),
      legend.title       = element_text(color = "#8b949e", size = 10),
      strip.text         = element_text(color = "#8b949e"),
      strip.background   = element_rect(fill = "#1c2330"),
      plot.margin        = margin(16, 16, 16, 16)
    )
}

emotion_palette <- c(
  happy    = "#3fb950",
  surprise = "#4f9cf9",
  neutral  = "#8b949e",
  sad      = "#a371f7",
  fear     = "#d29922",
  angry    = "#f85149",
  disgust  = "#e3b341"
)

# =====================================================
# UI
# =====================================================

ui <- fluidPage(
  tags$head(
    tags$style(HTML(custom_css)),
    tags$script(HTML(custom_js))
  ),
  
  # ── LOGIN OVERLAY ──────────────────────────────────
  div(id = "login_overlay",
      div(class = "login-card",
          div(class = "login-logo",
              div(class = "logo-icon", "🎓"),
              
              tags$p("Student Engagement & Attendance Dashboard")
          ),
          div(class = "login-field",
              tags$label("Username"),
              tags$input(id = "login_user", type = "text",  placeholder = "Enter username", autocomplete = "off")
          ),
          div(class = "login-field",
              tags$label("Password"),
              tags$input(id = "login_pass", type = "password", placeholder = "Enter password")
          ),
          tags$button(id = "do_login", class = "login-btn", "Sign In"),
          div(id = "login_error_msg", class = "login-error", "Invalid credentials. Please try again.")
      )
  ),
  
  # ── MAIN APP (hidden until login) ─────────────────
  div(id = "main_app", style = "display:none;",
      
      # TOP NAVBAR
      div(class = "top-navbar",
          div(class = "navbar-brand",
              span(class = "brand-dot"),
              "Analysis Dashboard"
          ),
          div(class = "navbar-user",
              div(class = "user-badge",
                  div(class = "user-avatar",
                      span(id = "user_avatar_letter", "A")
                  ),
                  div(class = "user-info",
                      div(class = "user-name",  id = "user_name_display",  "—"),
                      div(class = "user-role",  id = "user_role_display",  "—")
                  )
              ),
              tags$button(id = "logout_btn", class = "logout-btn", "⏻  Logout")
          )
      ),
      
      # BODY
      div(class = "app-layout",
          
          # ── SIDEBAR ───────────────────────────────────
          div(class = "app-sidebar",
              
              div(class = "sidebar-section-label", "Lecture"),
              div(class = "sidebar-select",
                  selectInput(
                    "selected_lecture", NULL,
                    choices = c("305_1", "305_2", "305_3", "1235_1", "1235_2", "1235_3"),
                    ,
                    selected = "305_2"
                  )
              ),
              
              div(class = "sidebar-section-label", "Filters"),
              sliderInput("min_conf", "Min. Confidence", min = 0, max = 100, value = 0),
              checkboxInput("show_unknown", "Show Unknown Students", value = FALSE),
              
              div(class = "sidebar-section-label", "Quick Stats"),
              uiOutput("quick_stats")
          ),
          
          # ── MAIN CONTENT ──────────────────────────────
          div(class = "app-main",
              tabsetPanel(
                
                # ATTENDANCE
                tabPanel("📋 Attendance",
                         h3("Attendance Tracking"),
                         fluidRow(
                           column(6,
                                  div(class="plot-card",
                                      div(class="plot-card-title", div(class="dot"), "Attendance Overview"),
                                      plotOutput("attendance_pie", height="310px")
                                  )
                           )
                         ),
                         div(class="plot-card",
                             div(class="plot-card-title", div(class="dot"), "Student List"),
                             tableOutput("attendance_table")
                         )
                ),
                
                # OVERVIEW
                tabPanel("📊 Overview",
                         fluidRow(
                           column(6,
                                  div(class="plot-card",
                                      div(class="plot-card-title", div(class="dot"), "Emotion Frequency"),
                                      plotOutput("emotion_distribution", height="280px")
                                  )
                           ),
                           column(6,
                                  div(class="plot-card",
                                      div(class="plot-card-title", div(class="dot"), "Engagement Score Distribution"),
                                      plotOutput("engagement_distribution", height="280px")
                                  )
                           )
                         ),
                         div(class="plot-card",
                             div(class="plot-card-title", div(class="dot"), "Emotion by Lecture"),
                             plotOutput("lecture_emotions", height="280px")
                         )
                ),
                
                # TIME TRENDS
                tabPanel("📈 Time Trends",
                         div(class="plot-card",
                             div(class="plot-card-title", div(class="dot"), "Engagement Over Time"),
                             plotOutput("engagement_trend", height="280px")
                         ),
                         div(class="plot-card",
                             div(class="plot-card-title", div(class="dot"), "Emotion Over Time"),
                             plotOutput("emotion_trend", height="280px")
                         )
                ),
                
                # STUDENTS
                tabPanel("👥 Students",
                         div(class="plot-card",
                             div(class="plot-card-title", div(class="dot"), "Average Engagement per Student"),
                             plotOutput("student_engagement", height="280px")
                         ),
                         div(class="plot-card",
                             div(class="plot-card-title", div(class="dot"), "Student × Lecture Heatmap"),
                             plotOutput("student_heatmap", height="560px")
                         )
                ),
                
                # LIVE CAM
                tabPanel("📷 Live Camera",
                         div(class="plot-card",
                             div(class="plot-card-title", div(class="dot"), "Live Feed"),
                             tags$img(id="live_cam", src="latest_frame.jpg", width="100%")
                         )
                ),
                
                # RAW DATA
                tabPanel("📝 Raw Data",
                         div(class="plot-card",
                             div(class="plot-card-title", div(class="dot"), "Latest 50 Records"),
                             tableOutput("raw_table")
                         )
                )
              )
          )
      )
  )
)

# =====================================================
# SERVER
# =====================================================

server <- function(input, output, session) {
  
  # ── AUTH STATE ────────────────────────────────────
  logged_in   <- reactiveVal(FALSE)
  current_user <- reactiveVal(NULL)
  
  observeEvent(input$login_attempt, {
    attempt <- input$login_attempt
    match <- NULL
    for (u in valid_users) {
      if (u$username == attempt$user && u$password == attempt$pass) {
        match <- u; break
      }
    }
    if (!is.null(match)) {
      logged_in(TRUE)
      current_user(match)
      session$sendCustomMessage("showApp", list(show = TRUE))
      session$sendCustomMessage("updateUserBadge", list(
        name   = match$name,
        role   = match$role,
        letter = toupper(substr(match$name, 1, 1))
      ))
    } else {
      session$sendCustomMessage("loginError", list(text = "Invalid username or password."))
    }
  })
  
  observeEvent(input$logout_clicked, {
    logged_in(FALSE)
    current_user(NULL)
    session$sendCustomMessage("showApp", list(show = FALSE))
  })
  
  # ── DATA LOADING ──────────────────────────────────
  reactive_emotion_data <- reactive({
    invalidateLater(3000, session)
    load_emotion_data()
  })
  
  reactive_attendance_data <- reactive({
    invalidateLater(3000, session)
    load_attendance_data()
  })
  
  observe({
    invalidateLater(50, session)
    session$sendCustomMessage(
      type = "updateImage",
      message = list(url = paste0("latest_frame.jpg?t=", Sys.time()))
    )
  })
  
  # ── FILTERED DATA ─────────────────────────────────
  filtered_data <- reactive({
    data <- reactive_emotion_data()
    if (nrow(data) == 0) return(data)
    data <- data %>% filter(confidence >= input$min_conf)
    if (!input$show_unknown) data <- data %>% filter(student_id != "Unknown")
    data <- data %>% filter(lecture_id == input$selected_lecture)
    data
  })
  
  filtered_attendance <- reactive({
    data <- reactive_attendance_data()
    if (nrow(data) == 0) return(data)
    data %>% filter(lecture_id == input$selected_lecture)
  })
  
  all_known_students <- reactive({
    data <- reactive_emotion_data()
    if (nrow(data) == 0) return(character(0))
    students <- unique(data$student_id)
    students[students != "Unknown"]
  })
  
  # ── QUICK STATS ───────────────────────────────────
  output$quick_stats <- renderUI({
    data <- filtered_data()
    att  <- filtered_attendance()
    all_s <- all_known_students()
    
    present <- length(unique(att$student_id))
    avg_eng <- if (nrow(data) > 0) round(mean(data$engagement_score, na.rm = TRUE), 2) else 0
    
    tagList(
      div(class="stat-card",
          div(class="stat-label", "✅ Present Students"),
          div(class="stat-value green", present)
      ),
      div(class="stat-card",
          div(class="stat-label", "📊 Avg Engagement"),
          div(class="stat-value blue", avg_eng)
      ),
      div(class="stat-card",
          div(class="stat-label", "🎓 Total Known"),
          div(class="stat-value", length(all_s))
      ),
      div(class="stat-card",
          div(class="stat-label", "📝 Records"),
          div(class="stat-value", nrow(data))
      )
    )
  })
  
  # ── EMPTY PLOT ─────────────────────────────────────
  empty_plot <- function(msg = "No data available") {
    ggplot() +
      annotate("text", x=0.5, y=0.5, label=msg, color="#8b949e", size=5) +
      xlim(0,1) + ylim(0,1) +
      dark_theme() +
      theme(panel.grid=element_blank(), axis.text=element_blank(), axis.title=element_blank())
  }
  
  # ── ATTENDANCE PIE ────────────────────────────────
  output$attendance_pie <- renderPlot({
    att <- filtered_attendance()
    all_s <- all_known_students()
    if (length(all_s) == 0) return(empty_plot("No student data"))
    
    present_count <- length(intersect(unique(att$student_id), all_s))
    absent_count  <- length(all_s) - present_count
    df <- data.frame(Status=c("Present","Absent"), Count=c(present_count, absent_count))
    
    ggplot(df, aes(x="", y=Count, fill=Status)) +
      geom_bar(stat="identity", width=1, color="#161b22", linewidth=2) +
      coord_polar("y", start=0) +
      scale_fill_manual(values=c("Present"="#3fb950","Absent"="#f85149")) +
      geom_text(aes(label=paste0(Count,"\n(",round(Count/sum(Count)*100,1),"%)")),
                position=position_stack(vjust=0.5), size=5, color="white", fontface="bold") +
      dark_theme() +
      theme(axis.text=element_blank(), axis.title=element_blank(),
            panel.grid=element_blank(), legend.position="bottom") +
      labs(title=NULL, fill=NULL)
  }, bg="#161b22")
  
  # ── ATTENDANCE BAR ────────────────────────────────
  output$attendance_bar <- renderPlot({
    att  <- filtered_attendance()
    all_s <- all_known_students()
    if (length(all_s) == 0) return(empty_plot())
    
    present_s <- unique(att$student_id)
    df <- data.frame(student_id=all_s,
                     Present=ifelse(all_s %in% present_s, "Present","Absent"),
                     stringsAsFactors=FALSE)
    
    ggplot(df, aes(x=reorder(student_id, Present=="Present"), fill=Present)) +
      geom_bar(width=0.65) +
      scale_fill_manual(values=c("Present"="#3fb950","Absent"="#f85149")) +
      coord_flip() +
      dark_theme() +
      theme(legend.position="bottom") +
      labs(x=NULL, y="Count", fill=NULL)
  }, bg="#161b22")
  
  # ── ATTENDANCE TABLE ──────────────────────────────
  output$attendance_table <- renderTable({
    att   <- filtered_attendance()
    all_s <- all_known_students()
    
    if (nrow(att) == 0) {
      return(data.frame(Student=as.character(all_s), Status="Not Checked In",
                        First_Seen="-", Times_Detected=0))
    }
    att_sum <- att %>%
      group_by(student_id) %>%
      summarise(First_Seen=format(min(timestamp),"%H:%M:%S"),
                Times_Detected=n(), .groups='drop') %>%
      mutate(Status="Present")
    
    absent_s <- setdiff(all_s, unique(att$student_id))
    if (length(absent_s) > 0) {
      att_sum <- rbind(att_sum,
                       data.frame(student_id=absent_s, First_Seen="-",
                                  Times_Detected=0, Status="Absent",
                                  stringsAsFactors=FALSE))
    }
    att_sum %>%
      rename(Student=student_id) %>%
      arrange(Student)
  }, striped=FALSE, bordered=FALSE, hover=TRUE)
  
  # ── EMOTION DISTRIBUTION ──────────────────────────
  output$emotion_distribution <- renderPlot({
    data <- filtered_data()
    if (nrow(data) == 0) return(empty_plot())
    
    ggplot(data, aes(x=reorder(emotion, emotion, function(x) -length(x)), fill=emotion)) +
      geom_bar(width=0.65) +
      scale_fill_manual(values=emotion_palette) +
      dark_theme() +
      theme(legend.position="none") +
      labs(x=NULL, y="Count")
  }, bg="#161b22")
  
  # ── ENGAGEMENT DISTRIBUTION ───────────────────────
  output$engagement_distribution <- renderPlot({
    data <- filtered_data()
    if (nrow(data) == 0) return(empty_plot())
    
    ggplot(data, aes(x=engagement_score)) +
      geom_histogram(bins=25, fill="#4f9cf9", color="#161b22", linewidth=0.3, alpha=0.9) +
      dark_theme() +
      labs(x="Engagement Score", y="Frequency")
  }, bg="#161b22")
  
  # ── LECTURE EMOTIONS ──────────────────────────────
  output$lecture_emotions <- renderPlot({
    data <- filtered_data()
    if (nrow(data) == 0) return(empty_plot())
    
    # Calculate emotion proportions
    emotion_counts <- data %>%
      count(emotion) %>%
      mutate(proportion = n / sum(n),
             percentage = scales::percent(proportion, accuracy = 1))
    
    # Create pie chart with labels
    ggplot(emotion_counts, aes(x="", y=proportion, fill=emotion)) +
      geom_bar(stat="identity", width=1) +
      coord_polar("y", start=0) +
      geom_text(aes(label = percentage), 
                position = position_stack(vjust = 0.5)) +
      scale_fill_manual(values=emotion_palette) +
      dark_theme() +
      labs(fill="Emotion") +
      theme(axis.title.x = element_blank(),
            axis.title.y = element_blank(),
            axis.text.x = element_blank(),
            axis.text.y = element_blank(),
            axis.ticks = element_blank())
  }, bg="#161b22")
  
  # ── ENGAGEMENT TREND ──────────────────────────────
  output$engagement_trend <- renderPlot({
    data <- filtered_data()
    if (nrow(data) == 0) return(empty_plot())
    
    trend <- data %>%
      group_by(time_bin) %>%
      summarise(avg=mean(engagement_score, na.rm=TRUE), .groups='drop')
    
    ggplot(trend, aes(x=time_bin, y=avg)) +
      geom_area(fill="#4f9cf9", alpha=0.15) +
      geom_line(color="#4f9cf9", linewidth=1.2) +
      geom_point(color="#4f9cf9", size=2.5) +
      dark_theme() +
      labs(x="Time", y="Avg Engagement Score")
  }, bg="#161b22")
  
  # ── EMOTION TREND ─────────────────────────────────
  output$emotion_trend <- renderPlot({
    data <- filtered_data()
    if (nrow(data) == 0) return(empty_plot())
    
    et <- data %>%
      group_by(time_bin, emotion) %>%
      summarise(count=n(), .groups='drop')
    
    ggplot(et, aes(x=time_bin, y=count, color=emotion)) +
      geom_line(linewidth=1) +
      scale_color_manual(values=emotion_palette) +
      dark_theme() +
      labs(x="Time", y="Count", color="Emotion")
  }, bg="#161b22")
  
  # ── STUDENT ENGAGEMENT ────────────────────────────
  output$student_engagement <- renderPlot({
    data <- filtered_data()
    if (nrow(data) == 0) return(empty_plot())
    
    ss <- data %>%
      group_by(student_id) %>%
      summarise(engagement=mean(engagement_score, na.rm=TRUE), .groups='drop') %>%
      arrange(desc(engagement))
    
    ggplot(ss, aes(x=reorder(student_id, engagement), y=engagement)) +
      geom_col(fill="#38d9a9", width=0.6) +
      coord_flip() +
      dark_theme() +
      labs(x=NULL, y="Avg Engagement")
  }, bg="#161b22")
  
  # ── HEATMAP ───────────────────────────────────────
  output$student_heatmap <- renderPlot({
    data <- reactive_emotion_data()
    if (nrow(data) == 0) return(empty_plot())
    
    hd <- data %>%
      filter(student_id != "Unknown") %>%
      group_by(student_id, lecture_id) %>%
      summarise(engagement=mean(engagement_score, na.rm=TRUE), .groups='drop')
    
    ggplot(hd, aes(x=lecture_id, y=student_id, fill=engagement)) +
      geom_tile(color="#161b22", linewidth=1.5) +
      scale_fill_gradient(low="#1a2744", high="#38d9a9") +
      dark_theme() +
      labs(x="Lecture", y="Student", fill="Engagement") +
      theme(axis.text.x=element_text(angle=0))
  }, bg="#161b22")
  
  # ── RAW TABLE ─────────────────────────────────────
  output$raw_table <- renderTable({
    data <- filtered_data()
    if (nrow(data) == 0) return(data.frame(Message="No data"))
    head(data[, c("student_id","timestamp","emotion","confidence","lecture_id")], 50)
  }, striped=FALSE, hover=TRUE)
}
# =====================================================
# RUN
# =====================================================
shinyApp(ui=ui, server=server)