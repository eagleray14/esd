## Read the sea levels for tidal gauges (EU-Circle & eSACP)
## Rasmus.Benestad@met.no, 2016-01-29, Meteorologisk institutt, Oslo, Norway

## French tidal stations: http://www.sonel.org/-Tide-gauges,29-.html?lang=en
## Daily means



station.sonel <- function(urls=c('http://www.sonel.org/msl/Demerliac/VALIDATED/dCHERB.slv',
                             'http://www.sonel.org/msl/Demerliac/VALIDATED/dRSCOF.slv',
                             'http://www.sonel.org/msl/Demerliac/VALIDATED/dLCONQ.slv',
                             'http://www.sonel.org/msl/Demerliac/VALIDATED/dBREST.slv',
                             'http://www.sonel.org/msl/Demerliac/VALIDATED/dHAVRE.slv',
                             'http://www.sonel.org/msl/Demerliac/VALIDATED/dDIEPP.slv',
                             'http://www.sonel.org/msl/Demerliac/VALIDATED/dBOULO.slv',
                             'http://www.sonel.org/msl/Demerliac/VALIDATED/dCALAI.slv',
                             'http://www.sonel.org/msl/Demerliac/VALIDATED/dDUNKE.slv',
                             'http://www.sonel.org/msl/Demerliac/VALIDATED/dCONCA.slv',
                             'http://www.sonel.org/msl/Demerliac/VALIDATED/dPTUDY.slv',
                             'http://www.sonel.org/msl/Demerliac/VALIDATED/dSNAZA.slv',
                             'http://www.sonel.org/msl/Demerliac/VALIDATED/dBOUCA.slv',
                             'http://www.sonel.org/msl/Demerliac/VALIDATED/dSJLUZ.slv',
                             'http://www.sonel.org/msl/Demerliac/VALIDATED/dPBLOC.slv',
                             'http://www.sonel.org/msl/Demerliac/VALIDATED/dLROCH.slv'),
                      verbose=FALSE) {

  param='sea-level'; unit='mm'; src='sonel'; cntr='France'

  loc <- c('CHERBOURG','ROSCOFF','LE_CONQUET','BREST','LE_HAVRE','DIEPPE',
           'BOULOGNE-SUR-MER','CALAIS','DUNKERQUE','CONCARNEAU','PORT TUDY',
           'SAINT-NAZAIRE','BOUCAU-BAYONNE','SAINT JEAN-DE-LUZ','PORT_BLOC',
           'LA ROCHELLE')
  lon <- c(-1.63563001,-3.96585989,-4.78082991,-4.49483800,0.10599000,1.08444000,1.57746005,
           1.86772001,2.36664009,-3.90738010,-3.44585200,-2.20155000,-1.51482999,-1.68162300,
           -1.06157005,-1.22073600)
  lat <- c(49.65129852,48.71839905,48.35940170,48.38285000,49.48189926,49.92918000,50.72750092,
           50.96939850,51.04809952,47.87369919,47.64427400,47.26686200,43.52730179,43.39523900,
           45.56850052,46.15847800)

  for (i in 1:length(urls)) {
    if (verbose) print(paste(i,loc[i],urls[i]))
    sl <- read.table(urls[i])
    x <- zoo(sl[[2]],order.by=as.Date(sl[[1]]))
    y <- as.station(x,param=param,unit=unit,loc=loc[i],lon=lon[i],lat=lat[i],
                    src=src,cntr=cntr,url=urls[i])
    if (i==1) Y <- y else Y <- combine(Y,y)
  }
  return(Y)
}

## http://browse.ceda.ac.uk/browse/badc/CDs/gloss/data/glosshlp.txt
## http://browse.ceda.ac.uk/browse/badc/CDs/gloss/data
## Monthly means
station.gloss <- function(url='http://browse.ceda.ac.uk/browse/badc/CDs/gloss/data') {
  lonlat <- read.table(paste(url,'glosspos.dat',sep='/'))
  data(glossstations)
  #glossstations <- read.table('glossstations.txt',sep='\t')
  SL <- read.fwf(paste(url,'psmsl.dat',sep='/'),skip=2,
                 widths=c(3,4,4,32,rep(5,14)),
                 col.names=c('XRE','CCO','SCO','location','year',month.abb,'annual'))
  Xt <- table(SL$location)
  n <- length(names(Xt))
  yearmon <- seq(min(SL$year,na.rm=TRUE),max(SL$year,na.rm=TRUE)+11/12,by=1/12)
  X <- matrix(rep(NA,n*length(yearmon)),n,length(yearmon));
  loc <- names(Xt)
  loc <- gsub('  ','',loc)
  loc <- substr(loc,2,nchar(loc)-1)
  lon <- rep(NA,n); lat <- rep(NA,n); cntr <- rep('NA',n)
  for (i in 1:n) {
    ii <- is.element(as.character(SL$location),names(Xt)[i])
    yrmn <- seq(min(SL$year[ii],na.rm=TRUE),max(SL$year[ii],na.rm=TRUE)+11/12,by=1/12)
    yrmn <- yrmn[is.element(trunc(yrmn),SL$year[ii])]
    i1 <- is.element(yearmon,yrmn)
    i2 <- is.element(yrmn,yearmon)
    x <- c(t(SL[ii,6:17]))
    X[i,i1] <- as.numeric(x)[i2]
    iii <- is.element(substr(toupper(glossstations$V1),1,nchar(loc[i])),toupper(loc[i]))
    if (sum(iii)>0) {
      lon[i] <- glossstations$V5[iii]
      lat[i] <- glossstations$V4[iii]
      cntr[i] <- glossstations$V2[iii]
    }
  }
  Y <- zoo(t(X),order.by=as.Date(paste(trunc(yearmon),
                  round(12*(yearmon-trunc(yearmon)))+1,'01',sep='-')))
  Y <- as.station(Y,loc=loc,param='sea-level',unit='mm',info='http://www.gloss-sealevel.org/',
                  lon=lon,lat=lat,alt=rep(0,n),cntr=cntr,url=url,src='GLOSS')
  return(Y)
}

## Newlyn
## http://www.gloss-sealevel.org/station_handbook/stations/241/#.VqnZSkL4phh
station.newlyn <- function(path='data/gloss-241_Newlyn',verbose=TRUE) {
  if (!file.exists(path)) {
    download.file('http://www.gloss-sealevel.org/extlink/https%3A//www.bodc.ac.uk/data/online_delivery/international_sea_level/gloss/ascii/g241.zip',destfile='newlyn.zip')
    dir.create(path)
    system(paste('unzip newlyn.zip d',path))
  }
  metadata <- read.table(paste(path,'ig241.txt',sep='/'),skip=5,nrows=1)
  files <- list.files(path=path,pattern='.lst',full.name=TRUE)
  for (i in 1:length(files)) {
    if (verbose) print(files[i])
    testline <- readLines(files[i],n=1)
    if (substr(testline,1,4)=='BODC') xin <- try(read.table(files[i],skip=13)) else {
      xxin <- readLines(files[i])
      keeplines <- grep('/',xxin)
      xxin <- xxin[keeplines]
      keeplines <- grep(')',xxin)
      writeLines(con='newlyn.txt',xxin[keeplines])
      xin <- try(read.table('newlyn.txt'))
    }
    if (inherits(xin,"try-error")) print('failed') else {
      yymmdd <- gsub('/','-',as.character(xin$V2))
      if (verbose) print(c(yymmdd[1],yymmdd[length(yymmdd)]))
      hr <- gsub('.',':',as.character(xin$V3),fixed=TRUE)
      if (i==1) z <- zoo(xin$V4*1000,order.by=as.POSIXlt(paste(yymmdd,hr))) else {
        zz <- zoo(xin$V4*1000,order.by=as.POSIXlt(paste(yymmdd,hr)))
        it1 <- !is.element(index(z),index(zz))
        t <- c(index(z)[it1],index(zz))
        z <- zoo(c(coredata(z),coredata(zz)),order.by=t)
      }
    }
  }
  
  z <- as.station(z,loc=metadata$V1,lon=metadata$V4,lat=metadata$V3,alt=0,src='GLOSS',
                  cntr='UK',param='sea-level',unit='mm',
                  url='http://www.gloss-sealevel.org/station_handbook/stations/241/#.VqnZSkL4phh')

  class(z) <- c('station','hour','zoo')
  return(z)

 
}
