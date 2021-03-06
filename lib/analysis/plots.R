# Clear
rm(list = ls())
cat("\014")

# Check for Database Connection Settings
if(!file.exists("db.settings.R")){
  stop(sprintf("db.settings.R file not found."))
}

# Include Libraries
source("db.settings.R")
source("includes.R")

# Initialize Libraries
init.libraries()

# ggplot Theme
plot.theme <-
  theme_bw() +
  theme(
    plot.title = element_text(
      size = 14, face = "bold", margin = margin(5,0,25,0)
    ),
    axis.text.x = element_text(size = 10, angle = 50, vjust = 1, hjust = 1),
    axis.title.x = element_text(face = "bold", margin = margin(15,0,5,0)),
    axis.text.y = element_text(size = 10),
    axis.title.y = element_text(face = "bold", margin = margin(0,15,0,5)),
    strip.text.x = element_text(size = 10, face = "bold"),
    legend.position = "bottom",
    legend.title = element_text(size = 9, face = "bold"),
    legend.text = element_text(size = 9)
  )

###############################################################################
## Density and Correlation Plots
###############################################################################

#### Query Data
query <- "
  SELECT release,
    num_participants,
    -- Switch
    becomes_vulnerable,
    -- Control Metric
    sloc,
    -- Bug Metrics: Reference
    num_pre_bugs,
    -- Bug Metrics: Categories
    num_pre_build_bugs,
    num_pre_tests_fails_bugs,
    num_pre_features,
    num_pre_security_bugs,
    num_pre_stability_crash_bugs,
    num_pre_compatibility_bugs,
    num_pre_regression_bugs,
    -- Review Experience Metrics
    avg_build_experienced_participants,
    avg_compatibility_experienced_participants,
    avg_security_experienced_participants,
    avg_bug_security_experienced_participants,
    avg_stability_experienced_participants,
    avg_test_fail_experienced_participants
  FROM release_filepaths
  ORDER BY CAST(release AS NUMERIC) ASC
"

db.connection <- get.db.connection(db.settings)
dataset <- dbGetQuery(db.connection, query)
dbDisconnect(db.connection)

##########################################
### Bug Metrics
##########################################

plot.dataset <- filter.dataset(dataset, filter.type = "bug")

#####################
### Density Plots
#####################

### Base
#### Export Resolution: 400 x 460
ggplot(plot.dataset, aes(x = becomes_vulnerable, y = sloc)) +
  geom_violin(aes(fill = becomes_vulnerable), alpha = 0.3) +
  geom_boxplot(width = 0.07, outlier.size = 1) +
  scale_x_discrete(breaks = c("TRUE", "FALSE"), labels = c("Yes", "No")) +
  scale_y_log10() +
  scale_fill_manual(
    values = c("TRUE" = "#636363", "FALSE" = "#f0f0f0"),
    labels = c("TRUE" = "Yes", "FALSE" = "No"),
    name = "Vulnerable"
  ) +
  labs(
    title = "Distribution of SLOC",
    x = "Vulnerable", y = "Metric Value (Log Scale)"
  ) +
  plot.theme +
  theme(legend.position = "none")

### Reference
#### Export Resolution: 400 x 460
ggplot(plot.dataset, aes(x = becomes_vulnerable, y = num_pre_bugs)) +
  geom_violin(aes(fill = becomes_vulnerable), alpha = 0.3) +
  geom_boxplot(width = 0.07, outlier.size = 1) +
  scale_x_discrete(breaks = c("TRUE", "FALSE"), labels = c("Yes", "No")) +
  scale_y_log10() +
  scale_fill_manual(
    values = c("TRUE" = "#636363", "FALSE" = "#f0f0f0"),
    labels = c("TRUE" = "Yes", "FALSE" = "No"),
    name = "Vulnerable"
  ) +
  labs(
    title = "Distribution of num-pre-bugs",
    x = "Vulnerable", y = "Metric Value (Log Scale)"
  ) +
  plot.theme +
  theme(legend.position = "none")


### Categories
#### Prepare Plotting Data Set
COLUMN.LABELS <- list(
  "num_pre_build_bugs" = "num-pre-build-bugs",
  "num_pre_compatibility_bugs" = "num-pre-comptability-bugs",
  "num_pre_features" = "num-pre-feature",
  "num_pre_regression_bugs" = "num-pre-regression-bugs",
  "num_pre_security_bugs" = "num-pre-security-bugs",
  "num_pre_stability_crash_bugs" = "num-pre-stability-bugs",
  "num_pre_tests_fails_bugs" = "num-pre-tests-fails-bugs"
)
plot.source <- data.frame()
plots <- list()
plot.index <- 1
row.index <- 1
row.numplots <- 3
for(index in 1:length(COLUMN.LABELS)){
  cat("[Row ", row.index, "] ", COLUMN.LABELS[[index]], "\n", sep = "")
  plot.source <- rbind(
    plot.source,
    data.frame(
      "label" = COLUMN.LABELS[[index]],
      "value" = plot.dataset[[names(COLUMN.LABELS)[index]]],
      "release" = factor(
        plot.dataset$release, levels = unique(plot.dataset$release)
      ),
      "becomes_vulnerable" = plot.dataset$becomes_vulnerable
    )
  )

  if(index %% row.numplots == 0){
    plots[[row.index]] <- ggplotGrob(
      ggplot(plot.source, aes(x = becomes_vulnerable, y = value)) +
        geom_violin(aes(fill = becomes_vulnerable), alpha = 0.3) +
        geom_boxplot(width = 0.07, outlier.size = 1) +
        scale_x_discrete(breaks = c("TRUE", "FALSE"), labels = c("Yes", "No")) +
        scale_y_log10() +
        scale_fill_manual(
          values = c("TRUE" = "#636363", "FALSE" = "#f0f0f0"),
          labels = c("TRUE" = "Yes", "FALSE" = "No"),
          name = "Vulnerable"
        ) +
        facet_wrap(~ label, nrow = 1, scales = "free") +
        labs(
          title = NULL, x = NULL, y = NULL
        ) +
        plot.theme +
        theme(
          legend.position = "none", plot.margin = unit(c(0,5.5,0,5.5), "pt")
        )
    )

    plot.source <- data.frame()

    row.index <- row.index + 1
  }
}

# Last Row of Density Plots
plots[[row.index]] <- ggplotGrob(
  ggplot(plot.source, aes(x = becomes_vulnerable, y = value)) +
    geom_violin(aes(fill = becomes_vulnerable), alpha = 0.3) +
    geom_boxplot(width = 0.07, outlier.size = 1) +
    scale_x_discrete(breaks = c("TRUE", "FALSE"), labels = c("Yes", "No")) +
    scale_y_log10() +
    scale_fill_manual(
      values = c("TRUE" = "#636363", "FALSE" = "#f0f0f0"),
      labels = c("TRUE" = "Yes", "FALSE" = "No"),
      name = "Vulnerable"
    ) +
    facet_wrap(~ label, nrow = 1, scales = "free") +
    labs(
      title = NULL, x = "Vulnerable", y = NULL
    ) +
    plot.theme +
    theme(
      legend.position = "none", plot.margin = unit(c(0,5.5,0,5.5), "pt")
    )
)

#### Export Resolution: 1250 x 760
##### Two Rows Layout
ng = nullGrob()
plot.grid <- grid.arrange(
  heights = c(1, 1.2),
  arrangeGrob(plots[[1]], nrow = 1),
  arrangeGrob(ng, plots[[2]], ng, nrow = 1, widths = c(0.15, 1, 0.15)),
  top = textGrob(
    "    Distribution of Pre-release Bug Category Metrics\n",
    gp = gpar(fontsize = 14, fontface = "bold")
  ),
  left = textGrob(
    "Metric Value (Log Scale)", rot = 90,
    gp = gpar(fontsize = 12, fontface = "bold")
  )
)

#### Export Resolution: 680 x 740
##### Three Rows Layout
ng = nullGrob()
plot.grid <- grid.arrange(
  heights = unit(c(1, 1, 1.1), "null"),
  arrangeGrob(plots[[1]], nrow = 1),
  arrangeGrob(plots[[2]], nrow = 1),
  # NOTE: The widths parameter works only for the export resolution above.
  arrangeGrob(
    ng, plots[[3]], ng, nrow = 1, widths = c(1.05, 1, 1)
  ),
  top = textGrob(
    "    Distribution of Pre-release Bug Category Metrics\n",
    gp = gpar(fontsize = 14, fontface = "bold")
  ),
  left = textGrob(
    "Metric Value (Log Scale)", rot = 90,
    gp = gpar(fontsize = 12, fontface = "bold")
  )
)

##########################################
## Experience Metrics
##########################################

plot.dataset <- filter.dataset(dataset, filter.type = "experience")

#####################
### Density Plots
#####################

### Prepare Plotting Data Set
COLUMN.LABELS <- list(
  "avg_build_experienced_participants" = "build-experience",
  "avg_compatibility_experienced_participants" = "compatibility-experience",
  "avg_bug_security_experienced_participants" = "security-experience",
  "avg_stability_experienced_participants" = "stability-experience",
  "avg_test_fail_experienced_participants" = "test-fail-experience"
)
plot.source <- data.frame()
for(index in 1:length(COLUMN.LABELS)){
  cat(COLUMN.LABELS[[index]], "\n")
  plot.source <- rbind(
    plot.source,
    data.frame(
      "label" = COLUMN.LABELS[[index]],
      "value" = plot.dataset[[names(COLUMN.LABELS)[index]]],
      "release" = factor(
        plot.dataset$release, levels = unique(plot.dataset$release)
      ),
      "becomes_vulnerable" = plot.dataset$becomes_vulnerable
    )
  )
}

### Export Resolution: 1024 x 380
ggplot(plot.source, aes(x = becomes_vulnerable, y = value)) +
  geom_violin(aes(fill = becomes_vulnerable), alpha = 0.3) +
  geom_boxplot(width = 0.07, outlier.size = 1) +
  scale_x_discrete(breaks = c("TRUE", "FALSE"), labels = c("Yes", "No")) +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(
    values = c("TRUE" = "#636363", "FALSE" = "#f0f0f0"),
    labels = c("TRUE" = "Yes", "FALSE" = "No"),
    name = "Vulnerable"
  ) +
  facet_wrap(~ label, nrow = 1, scales = "fixed") +
  labs(
    title = "Distribution of Review Experience Metrics",
    x = "Vulnerable", y = "Metric Value"
  )+
  plot.theme +
  theme(legend.position = "none")

#####################
### Correlation Plots
#####################

### Prepare Plotting Data Set
COLUMN.LABELS <- list(
  "avg_build_experienced_participants" = "build-experience",
  "avg_compatibility_experienced_participants" = "compatibility-experience",
  "avg_bug_security_experienced_participants" = "security-experience",
  "avg_stability_experienced_participants" = "stability-experience",
  "avg_test_fail_experienced_participants" = "test-fail-experience"
)
plot.source <- data.frame()
for(release in unique(plot.dataset$release)){
  cat("Release", release, "\n")
  release.dataset <- plot.dataset[plot.dataset$release == release,]

  correlation <- cor(
    release.dataset[,names(COLUMN.LABELS)],
    method = "spearman", use = "complete"
  )

  # Correlation matrix is symteric so plot either upper or lower half
  correlation[lower.tri(correlation)] <- NA
  correlation.melted <- melt(correlation)
  correlation.melted <- na.omit(correlation.melted)

  plot.source <- rbind(
    plot.source,
    cbind(
      "release" = release,
      "label" = paste("Release", release),
      correlation.melted
    )
  )
}

#### Adding Correlation at the Entire Data Set Level
correlation <- cor(
  plot.dataset[,names(COLUMN.LABELS)],
  method = "spearman", use = "complete"
)

# Correlation matrix is symteric so plot either upper or lower half
correlation[lower.tri(correlation)] <- NA
correlation.melted <- melt(correlation)
correlation.melted <- na.omit(correlation.melted)

plot.source <- rbind(
    plot.source,
    cbind(
      "release" = "overall",
      "label" = "Overall",
      correlation.melted
    )
  )

# Export Resolution: (a) 1250 x 500 for one row (b) 840 x 840 for two rows
ggplot(data = plot.source, aes(Var2, Var1, fill = value)) +
  geom_tile() +
  geom_text(
    aes(Var2, Var1, label = sprintf("%.2f", value)), color = "black", size = 4
  ) +
  scale_x_discrete(labels = COLUMN.LABELS) +
  scale_y_discrete(labels = COLUMN.LABELS) +
  scale_fill_gradient2(
    low = "#636363", high = "#636363", mid = "#f0f0f0",
    midpoint = 0, limit = c(-1,1)
  ) +
  facet_wrap(~ label, nrow = 2, scales = "fixed") +
  guides(
    fill = guide_colorbar(
      barwidth = 10, barheight = 0.5,
      title = expression(paste("Spearman's ", rho)),
      title.position = "top", title.hjust = 0.5
    )
  ) +
  coord_fixed() +
  labs(
    title = "Correlation Among Review Experience Metrics", x = NULL, y = NULL
  ) +
  plot.theme +
  theme(
    panel.grid.major = element_blank(),
    panel.border = element_blank(),
    panel.background = element_blank(),
    axis.ticks = element_blank()
  )

###############################################################################
## Lift Curves
###############################################################################

#### Query Data
query <- "
  SELECT release,
    num_pre_features,
    num_pre_compatibility_bugs,
    num_pre_regression_bugs,
    num_pre_security_bugs,
    num_pre_tests_fails_bugs,
    num_pre_stability_crash_bugs,
    num_pre_build_bugs,
    becomes_vulnerable,
    sloc
  FROM release_filepaths
  WHERE sloc > 0
  ORDER BY CAST(release AS NUMERIC) ASC, (num_pre_bugs/sloc::float) DESC
"
db.connection <- get.db.connection(db.settings)
dataset <- db.get.data(db.connection, query)
db.disconnect(db.connection)

### Prepare Plotting Data Set
plot.dataset <- filter.dataset(dataset, filter.type = "bug")
plot.source <- data.frame()
for(release in unique(plot.dataset$release)){
  cat("Release", release, "\n")
  release.dataset <- plot.dataset[plot.dataset$release == release,]

  file.count <- nrow(release.dataset)
  vuln.count <- nrow(
    release.dataset[release.dataset$becomes_vulnerable == TRUE,]
  )

  file.percent <- numeric(length = nrow(release.dataset))
  vuln.percent <- numeric(length = nrow(release.dataset))

  vuln.found <- 0
  for(index in 1:nrow(release.dataset)){
    if(release.dataset[index,]$becomes_vulnerable == TRUE){
      vuln.found <- vuln.found + 1
    }
    vuln.percent[index] <- vuln.found / vuln.count
    file.percent[index] <- index / file.count
  }

  plot.source <- rbind(
    plot.source,
    data.frame(
      "release" = release,
      "label" = paste("Release", release),
      "vuln.percent" = vuln.percent,
      "file.percent" = file.percent
    )
  )
}

# Export Resolution: 1250 x 400
ggplot(plot.source, aes(x = file.percent, y = vuln.percent)) +
  geom_line(size = 1) +
  scale_x_continuous(
    labels = scales::percent, breaks = seq(0, 1.0, by = 0.1)
  ) +
  scale_y_continuous(labels = scales::percent) +
  facet_wrap(~ label, nrow = 1, scales = "fixed") +
  labs(title = "Lift Curves", x = "% Files", y = "% Vulnerable Files Found") +
  plot.theme
