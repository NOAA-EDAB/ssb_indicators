#Geret DePiper
#2022 State of the Ecosystem Recreational Fishing Report

PKG <- c("tidyr","ggplot2","openxlsx")
for (p in PKG) {
  if(!require(p,character.only = TRUE)) {  
    install.packages(p)
    require(p,character.only = TRUE)}
}


REC_DATA <- read.xlsx('F:/ESRs/ESR2025/Data/Rec_Days_Fished_2025.xlsx')
  
REC_DATA$P_Shore <- -(as.numeric(gsub(",","",REC_DATA$Shore))/as.numeric(gsub(",","",REC_DATA$All_Modes)))*
                          log(as.numeric(gsub(",","",REC_DATA$Shore))/as.numeric(gsub(",","",REC_DATA$All_Modes)))
  REC_DATA$P_Private <- -(as.numeric(gsub(",","",REC_DATA$Private_Rental))/as.numeric(gsub(",","",REC_DATA$All_Modes)))*
                          log(as.numeric(gsub(",","",REC_DATA$Private_Rental))/as.numeric(gsub(",","",REC_DATA$All_Modes)))
  REC_DATA$P_Party <- -(as.numeric(gsub(",","",REC_DATA$Party_Charter))/as.numeric(gsub(",","",REC_DATA$All_Modes)))*
                        log(as.numeric(gsub(",","",REC_DATA$Party_Charter))/as.numeric(gsub(",","",REC_DATA$All_Modes)))
  REC_DATA$Value <- exp(REC_DATA$P_Shore+REC_DATA$P_Private+REC_DATA$P_Party)
  E_SHANNON <- subset(REC_DATA, select=c('Time','Region','Value'))
    E_SHANNON$Units <- 'Effective Shannon'
    E_SHANNON$Var <- 'Recreational fleet effort diversity across modes'
    E_SHANNON$Source <- 'MRIP effort time series, processed to generate diversity measure.'

REC_DATA <- subset(REC_DATA, select=c('Time','Region','All_Modes'))
  names(REC_DATA) <- c('Time','Region','Value')
    REC_DATA$Value <- as.numeric(gsub(",","",REC_DATA$Value))
    REC_DATA$Units <- 'Number of days fished'
  REC_DATA$Var <- 'Recreational Effort'
  REC_DATA$Source <- 'MRIP effort time series.'
REC_DATA <- rbind(REC_DATA,E_SHANNON)
  write.csv(REC_DATA,file='F:/ESRs/ESR2025/Data/FINAL/Rec_angler_effort_2025.csv')
  
  ggplot(data=REC_DATA,aes(x=Time,y=Value, group=Region, color=Region))+
    geom_line()+facet_wrap(vars(Var), scales="free",nrow=2)

REC_DATA$Perc_Shore <- as.numeric(gsub(",","",REC_DATA$Shore))/as.numeric(gsub(",","",REC_DATA$All_Modes))
REC_DATA$Perc_Private <- as.numeric(gsub(",","",REC_DATA$Private_Rental))/as.numeric(gsub(",","",REC_DATA$All_Modes))
REC_DATA$Perc_Party <- as.numeric(gsub(",","",REC_DATA$Party_Charter))/as.numeric(gsub(",","",REC_DATA$All_Modes))

#MRIP Update changed participattion estimates, and S&T still working on appropriate estimation technique
# REC_PARTICIPANTS <- read.csv('X:/gdepiper/ESR2018/SOE/Data/Rec_Anglers_2018.csv', as.is=TRUE)
#   REC_PARTICIPANTS <- subset(REC_PARTICIPANTS, select=c('Time','Region','Participants'))
#   names(REC_PARTICIPANTS)  <- c('Time','Region','Value')
#   REC_PARTICIPANTS$Value <- as.numeric(gsub(",","",REC_PARTICIPANTS$Value))
#   REC_PARTICIPANTS$Var <- 'Recreational anglers'
#   REC_PARTICIPANTS$Units <- 'Number of anglers'
#   REC_PARTICIPANTS$Source <- 'MRFSS/MRIP Participation Time Series. Note that this measure only includes in-state anglers to avoid double-counting.'
#   REC_PARTICIPANTS$Region[REC_PARTICIPANTS$Region=='MID-ATLANTIC'] <- 'MA'
#   REC_PARTICIPANTS$Region[REC_PARTICIPANTS$Region=='NORTH ATLANTIC'] <- 'NE'
#  write.csv(REC_PARTICIPANTS,file='X:/gdepiper/ESR2018/SOE/Data/Rec_participants_2018.csv')
  

REC_HARVEST <- read.xlsx('F:/ESRs/ESR2025/Data/Rec_Seafood_2025.xlsx',)
  REC_HARVEST <- subset(REC_HARVEST, select=c('Time','Region','All_Modes'))
  names(REC_HARVEST) <- c('Time','Region','Value')
  REC_HARVEST$Value <- as.numeric(gsub(",","",REC_HARVEST$Value))
  REC_HARVEST$Var <- 'Recreational Seafood'
  REC_HARVEST$Units <- 'lbs of fish'
  REC_HARVEST$Source <- 'MRIP National harvest and release totals'
 write.csv(REC_HARVEST,file='F:/ESRs/ESR2025/Data/FINAL/REC_HARVEST_2025.csv')
 
 ggplot(data=REC_HARVEST,aes(x=Time,y=Value, group=Region, color=Region))+
   geom_line()
  
  MA_REC_CATCH <- read.xlsx('F:/ESRs/ESR2025/Data/MA_Rec_Species_Quantity_2025.xlsx')
  NE_REC_CATCH <- read.xlsx('F:/ESRs/ESR2025/Data/NE_Rec_Species_Quantity_2025.xlsx')

  REC_CATCH <- rbind(MA_REC_CATCH,NE_REC_CATCH)
    REC_CATCH$Value <-  as.numeric(gsub(",","",REC_CATCH$Value))
    TOT_REC_CATCH <- aggregate(Value~Time+Region, data=REC_CATCH, FUN=sum)
      names(TOT_REC_CATCH) <- c('Time','Region','Tot_Catch')
      REC_CATCH <- merge(REC_CATCH,TOT_REC_CATCH, by=c('Time','Region'))
  REC_CATCH$P_Catch <- -(REC_CATCH$Value/REC_CATCH$Tot_Catch*
    log(REC_CATCH$Value/REC_CATCH$Tot_Catch))
  REC_CATCH <- aggregate(P_Catch~Time+Region, data=REC_CATCH, FUN=sum)
    REC_CATCH$Value <- exp(REC_CATCH$P_Catch)
  REC_CATCH <- subset(REC_CATCH, select=c('Time','Region','Value'))
   REC_CATCH$Units <- 'Effective Shannon'
  REC_CATCH$Var <- 'Recreational Diversity of Catch' ##Species include: American Eel, Atlantic Cod, Atlantic Mackerel, Atlantic Sturgeon, Black Drum, Black Sea Bass, Bluefish, 
  ##Cobia, Haddock, Pollock, Red Drum, Scup, Spanish Mackerel, Spiny Dogfish, Spot, Spotted Seatrout, Striped Bass, Summer Flounder, Tautog, Tilefish, Weakfish, Winter Flounder,   
  #and All Other Species.
  REC_CATCH$Source <- 'MRIP catch time series.'
write.csv(REC_CATCH,file='F:/ESRs/ESR2026/Data/FINAL/Rec_Species_Diversity_2026.csv')

ggplot(data=REC_CATCH,aes(x=Time,y=Value, group=Region, color=Region))+ geom_line()
    
    DIVERSITY <-  read.csv("F:/ESRs/ESR2026/Data/MAFMCspeciesdiversity_2026.csv", as.is=TRUE)
    TEMP <-  read.csv("F:/ESRs/ESR2026/Data/NEFMCspeciesdiversity_2026.csv", as.is=TRUE)
    DIVERSITY <- rbind(DIVERSITY,TEMP)
    rm(TEMP)
    TEMP <-  read.csv("F:/ESRs/ESR2026/Data/MAFMCfleetdiversity_2026.csv", as.is=TRUE)
    DIVERSITY <- rbind(DIVERSITY,TEMP)
    rm(TEMP)
    TEMP <-  read.csv("F:/ESRs/ESR2026/Data/MAFMCfleetcount_2026.csv", as.is=TRUE)
    DIVERSITY <- rbind(DIVERSITY,TEMP)
    rm(TEMP)
    TEMP <-  read.csv("F:/ESRs/ESR2026/Data/NEFMCfleetcount_2026.csv", as.is=TRUE)
    DIVERSITY <- rbind(DIVERSITY,TEMP)
    rm(TEMP)
    TEMP <-  read.csv("F:/ESRs/ESR2026/Data/NEFMCavgfleetdiversity_2026.csv", as.is=TRUE)
    DIVERSITY <- rbind(DIVERSITY,TEMP)
    rm(TEMP) 
    
    DIVERSITY$DROP <- 0
    DIVERSITY$DROP[DIVERSITY$Time==2025] <- 1
    DIVERSITY <- DIVERSITY[which(DIVERSITY$DROP==0),]
    DIVERSITY$DROP <- NULL
  
    DIVERSITY$Source <- "Min-Yang's proprietary blend of VTR trip data and CFDBS prices, mixed with Vessel characteristics from PERMIT database, major VTR gear by permit, and a dash of love."
    write.csv(DIVERSITY,file='F:/ESRs/ESR2026/Data/FINAL/Commercial_Diversity_2026.csv')
    
    DIVERSITY$DROP <- 0
    DIVERSITY$DROP[DIVERSITY$Time==2024] <- 1
    DIVERSITY <- DIVERSITY[which(DIVERSITY$DROP==0),]
    DIVERSITY$DROP <- NULL
    
pdf(paste0("F:/ESRs/ESR2026/Data/Commercial_Permit_Catch_diversity_Oct2026.pdf"))
ggplot(data=DIVERSITY[which(DIVERSITY$Var=="Permit revenue species diversity"),], 
          aes(x=Time,y=Value, group = Region, col=Region)) + geom_line()
dev.off()

pdf(paste0("F:/ESRs/ESR2026/Data/Commercial_fleet_diversity_Oct2026.pdf"))
ggplot(data=DIVERSITY[which(DIVERSITY$Var=="Fleet diversity in revenue"),], 
       aes(x=Time,y=Value, group = Region, col=Region)) + geom_line()
dev.off()

pdf(paste0("F:/ESRs/ESR2026/Data/Commercial_fleet_count_Oct2026.pdf"))
ggplot(data=DIVERSITY[which(DIVERSITY$Var=="Fleet count"),], 
       aes(x=Time,y=Value, group = Region, col=Region)) + geom_line()
dev.off()

#Past commercial diversity for QA/AC
Past_DIVERSITY<- read.csv(file='F:/ESRs/ESR2025/Data/FINAL/Commercial_Diversity_2025.csv')

pdf(paste0("F:/ESRs/ESR2026/Data/Commercial_Permit_Catch_diversity_2025.pdf"))
ggplot(data=Past_DIVERSITY[which(Past_DIVERSITY$Var=="Permit revenue species diversity"),], 
       aes(x=Time,y=Value, group = Region, col=Region)) + geom_line()
dev.off()

pdf(paste0("F:/ESRs/ESR2026/Data/Commercial_fleet_diversity_2025.pdf"))
ggplot(data=Past_DIVERSITY[which(Past_DIVERSITY$Var=="Fleet diversity in revenue"),], 
       aes(x=Time,y=Value, group = Region, col=Region)) + geom_line()
dev.off()

pdf(paste0("F:/ESRs/ESR2026/Data/Commercial_fleet_count_2025.pdf"))
ggplot(data=Past_DIVERSITY[which(Past_DIVERSITY$Var=="Fleet count"),], 
       aes(x=Time,y=Value, group = Region, col=Region)) + geom_line()
dev.off()


pdf(paste0("F:/ESRs/ESR2025/Data/Rec_Catch_2025.pdf"))
ggplot(data= REC_CATCH, 
       aes(x=Time,y=Value, group = Region, col=Region)) + geom_line()
dev.off()

pdf(paste0("F:/ESRs/ESR2025/Data/Rec_Seafood_2025.pdf"))
ggplot(data= REC_HARVEST , 
       aes(x=Time,y=Value, group = Region, col=Region)) + geom_line()
dev.off()

pdf(paste0("F:/ESRs/ESR2025/Data/Rec_Effort_2025.pdf"))
ggplot(data= REC_DATA, 
       aes(x=Time,y=Value, group = Region, col=Region)) + 
  geom_line() +
  facet_wrap(vars(Var), scales="free")
dev.off()

Past_REC_CATCH<- read.csv(file='F:/ESRs/ESR2024/Data/FINAL/Rec_Species_Diversity_2024.csv')
pdf(paste0("F:/ESRs/ESR2025/Data/Rec_Catch_2024.pdf"))
ggplot(data= Past_REC_CATCH, 
       aes(x=Time,y=Value, group = Region, col=Region)) + geom_line()
dev.off()


Past_REC_HARVEST<- read.csv(file='F:/ESRs/ESR2024/Data/FINAL/REC_HARVEST_2024.csv')
pdf(paste0("F:/ESRs/ESR2025/Data/Rec_Seafood_2024.pdf"))
ggplot(data= Past_REC_HARVEST , 
       aes(x=Time,y=Value, group = Region, col=Region)) + geom_line()
dev.off()

Past_REC_Effort<- read.csv(file='F:/ESRs/ESR2024/Data/FINAL/Rec_angler_effort_2024.csv')
pdf(paste0("F:/ESRs/ESR2025/Data/Rec_Effort_2024.pdf"))
ggplot(data= Past_REC_Effort, 
       aes(x=Time,y=Value, group = Region, col=Region)) + 
  geom_line() +
  facet_wrap(vars(Var), scales="free")
dev.off()
