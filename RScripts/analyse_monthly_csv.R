# un script pour construire un data.frame a partir de fichier de simulation
# 1. on lit le contenu d'un dossier
# 2. on récupère l'identifiant du run
# 3. on le stcok dans un collonne
# 4. on le mets dans le data.frame final

library("dplyr")
library("ggplot2")
library("stringr")
library("reshape2")

rm(list = ls())

setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) #def repertoire de travail

path <- "../OutputFilesForR/"
file.names <- list.files(paste0(path))

file.names <- file.names[!is.na(stringr::str_extract(file.names, "\\d"))] ## filtre sur les fichier qui on un numero de mois

data.df <- data.frame()

for (i in 1:(length(file.names))){
  tmp <- read.csv(paste0(path,file.names[i]))                            ##lecture du premier CSV qui contient un nombre
  # Appliquer la soustraction de chaque ligne avec la valeur précédente
  tmp1 <- as.data.frame(lapply(tmp[,6:9], function(x) c(x[1], diff(x))))
  tmp <- cbind(tmp[,1:5],tmp1)
  tmp$run <- i      ## extraction du nombre depuis le nom du fichier
  data.df <- rbind(data.df, tmp)                                         ##ajout a data frame général, les données de tmp 
}


# saveRDS(data.df, "~/Téléchargements/runGama_arthur/bigDataFrame.rds") #sauvegarde dans un format compressé des données samplé
# truc <- readRDS("~/Téléchargements/runGama_arthur/bigDataFrame.rds")

# Calculer la moyenne par groupe
df_grouped <- data.df %>%
  group_by(current_date.month, current_date.year) %>%
  summarize(totalNflow = mean(totalNFlows), 
            totalCflow = mean(totalCFlows), 
            TT = mean(TT), 
            CThroughflow = mean(CThroughflow),
            .groups = 'drop'
            )

df_grouped$date <- as.Date(paste(df_grouped$current_date.year, sprintf("%02d", df_grouped$current_date.month), "01", sep = "-"), format = "%Y-%m-%d")
df_grouped <- df_grouped[,-c(1:2)]

df_grouped_diff <- data.frame(diff(df_grouped$totalNflow), diff(df_grouped$totalCflow), diff(df_grouped$TT), diff(df_grouped$CThroughflow))
df_grouped_diff$date <- df_grouped$date[-1]

write.csv(df_grouped, file="../OutputFiles/OutputsRScripts/230407-monthly_Long.csv")

# Conversion du data frame en format long avec la fonction melt()
df_long <- melt(df_grouped_diff, id.vars = "date")
levels(df_long$variable) <- c("totalNflow", "totalCflow", "TT", "CThroughflow")

# Création du graphique en utilisant ggplot2 et facet_grid()
ggplot(df_long, aes(x = date, y = value, group = variable, color = variable)) +
  geom_line() +
  geom_smooth(span = 0.25)+
  facet_grid(. ~ variable, scales = "free_y") +
  labs(title = "Moyenne de 50 réplications de 2020 à 2070")+
  theme_bw()+
  ylim(c(0,1234483))+
  theme(axis.text.x = element_text(angle = 45, hjust = 1), 
        legend.position = "none")

ggsave("../OutputFiles/img/230407-monthly_Long.png", height = 7, width = 18)
