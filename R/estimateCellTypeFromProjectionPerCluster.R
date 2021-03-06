#' Estimate the most likely cell type from the projection to the reference panel
#'
#' @param rca.obj RCA object.
#' @param homogeneity a parameter indicating the homogeneity of the cluster. If the difference is below this threshold, the cell type will be set to unknown. Default is NULL.
#' @return RCA object.
#' @export
#'

estimateCellTypeFromProjectionPerCluster <- function(rca.obj, homogeneity=NULL) {

    # Assign data to tmp variables
    projection <- rca.obj$projection.data
    clusterColors <- rca.obj$clustering.out$dynamicColorsList[[1]]

    # Returning the likeliest cell type of a cell irrespective of a confidence score
    cTIdfWU<-function(x){
         return(names(x)[which(x==max(x))])
    }

    # Determine the likeliest cell type for each cell.
    cellTypes<-list()
    for (i in c(1:dim(projection)[2])){
          cellTypes<-c(cellTypes,cTIdfWU(projection[,i]))
    }


    # Compute the cell type compositions of each cluster using per cell cell type predictions
    enrichmentAll<-c()
    for(type in unique(clusterColors)){
	index=which(clusterColors==type)
        enrichmentAll<-rbind(enrichmentAll,(cbind(type,table(unlist(cellTypes)[index]))))
    }
    enrichmentAll<-data.frame(cbind(row.names(enrichmentAll),enrichmentAll))
    colnames(enrichmentAll)<-c("CT","Cluster","Count")
    rownames(enrichmentAll)<-c(1:dim(enrichmentAll)[1])
    enrichmentAll$Count<-as.numeric(as.character(enrichmentAll$Count))
    totalCounts<-data.frame(dplyr::count(enrichmentAll,wt=Count,Cluster))
    enrichmentAll<-left_join(enrichmentAll,totalCounts,by="Cluster")
    enrichmentAll<-cbind(enrichmentAll,enrichmentAll$Count/enrichmentAll$n*100)
    colnames(enrichmentAll)[5]<-"Ratio"
    enrichmentAll$Ratio<-as.numeric(as.character(enrichmentAll$Ratio))
 
    # Determine the identity of a cluster with or without the option to set the cluster identity to unkown
    maxCellTypeCluster<-list()
    homologyScores<-list()
    for (type in unique(clusterColors)){
        subset<-enrichmentAll[which(enrichmentAll$Cluster==type),]
        maxIndex<-which(subset$Ratio==max(subset$Ratio))
        homologyScores<-c(homologyScores,subset$Ratio[maxIndex])
    if (is.null(homogeneity)){
        maxCellTypeCluster<-c(maxCellTypeCluster,as.character(subset$CT[maxIndex]))
    }else{
        if (subset$Ratio[maxIndex]>0.5){
            maxCellTypeCluster<-c(maxCellTypeCluster,as.character(subset$CT[maxIndex]))
        }else{
          maxCellTypeCluster<-c(maxCellTypeCluster,"Unkown")
        }
    }
}
    names(homologyScores)<-unique(clusterColors)
    names(maxCellTypeCluster)<-unique(clusterColors)
 
    clusterConfidence<-homologyScores[clusterColors]
    estimatedCellTypes<-maxCellTypeCluster[clusterColors]

    rca.obj$cell.Type.Estimate <- estimatedCellTypes
    rca.obj$cScore <- clusterConfidence


    # Return RCA object
    return(rca.obj)
}


