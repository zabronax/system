{
  colorScheme,
}:

''
  /* Firefox UI theming using Base16 colorScheme */
  :root {
    --base00: ${colorScheme.colors.base00}; /* Background */
    --base01: ${colorScheme.colors.base01}; /* Lighter Background */
    --base02: ${colorScheme.colors.base02}; /* Selection Background */
    --base03: ${colorScheme.colors.base03}; /* Comments */
    --base04: ${colorScheme.colors.base04}; /* Dark Foreground */
    --base05: ${colorScheme.colors.base05}; /* Default Foreground */
    --base06: ${colorScheme.colors.base06}; /* Light Foreground */
    --base07: ${colorScheme.colors.base07}; /* Light Background */
    --base08: ${colorScheme.colors.base08}; /* Red */
    --base09: ${colorScheme.colors.base09}; /* Orange */
    --base0A: ${colorScheme.colors.base0A}; /* Yellow */
    --base0B: ${colorScheme.colors.base0B}; /* Green */
    --base0C: ${colorScheme.colors.base0C}; /* Cyan */
    --base0D: ${colorScheme.colors.base0D}; /* Blue */
    --base0E: ${colorScheme.colors.base0E}; /* Magenta */
    --base0F: ${colorScheme.colors.base0F}; /* Brown */
  }

  /* Apply theme colors to Firefox UI */
  #navigator-toolbox {
    background-color: var(--base00) !important;
    color: var(--base05) !important;
  }

  /* Tab bar styling */
  #TabsToolbar {
    background-color: var(--base00) !important;
  }

  .tab-background {
    background-color: var(--base01) !important;
  }

  .tabbrowser-tab[selected="true"] .tab-background {
    background-color: var(--base02) !important;
  }

  .tab-label {
    color: var(--base05) !important;
  }

  /* Navigation bar */
  #nav-bar {
    background-color: var(--base00) !important;
    color: var(--base05) !important;
  }

  /* URL bar */
  #urlbar {
    background-color: var(--base01) !important;
    color: var(--base05) !important;
  }

  #urlbar-input {
    color: var(--base05) !important;
  }

  /* Bookmarks toolbar */
  #PersonalToolbar {
    background-color: var(--base00) !important;
    color: var(--base05) !important;
  }

  /* Sidebar */
  #sidebar-box {
    background-color: var(--base00) !important;
    color: var(--base05) !important;
  }

  /* Menu bar */
  #toolbar-menubar {
    background-color: var(--base00) !important;
    color: var(--base05) !important;
  }
''
