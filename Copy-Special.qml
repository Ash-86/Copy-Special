import QtQuick 2.0
import MuseScore 3.0

MuseScore {
    menuPath: "Plugins.Copy Special"
    description: "Copy individual notes."
    version: "1.0"
    
    //4.4 title: "Copy Special"
    //4.4 thumbnailName: "up.png"
    //4.4 categoryCode: "composing-arranging-tools"
	
	Component.onCompleted : {
        if (mscoreMajorVersion >= 4) {
            title= "Copy Special"
            thumbnailName = "up.png"
            categoryCode = "composing-arranging-tools"
        }
    }	
      
      
      
    onRun: {
        var els = curScore.selection.elements
          
        if (((typeof els[0])!=="undefined") && (els[0].type == Element.NOTE)) {
           
            copySelection();
            return;
        } else {
            console.log("Invalid selection");
            if (els.length>0) 
                console.log("els[0]="+els[0].userName());
            else
                console.log("no selection");
            return;
        }
    }
            
            
            
            
            
            
function copySelection() {
   

    var cursor = curScore.newCursor();               
    var els = curScore.selection.elements 

    
    var note=[]
    var Notes=[]

    for (var i in els){
        var track = els[i].track
        var staff = ~~(track/4)  
        var voice = track%4        
        var tick = els[i].parent.parent.tick  
        
        note = {staff:staff, voice:voice, track:track, tick:tick}  
        Notes.push(note)       
    }       

    
    var tracks=[]  ///get unique tracks of selected notes
    var staves=[]   //get unique staves of selected notes
    var ticks=[]     //get unique ticks of selected notes
    for (var i in Notes){
        if(!tracks.some(function(x){return x==Notes[i].track})){
            tracks.push(Notes[i].track)
        }       
        if(!staves.some(function(x){return x==Notes[i].staff})){
            staves.push(Notes[i].staff)
        }                       
        if(!ticks.some(function(x){return x==Notes[i].tick})){                          
            ticks.push(Notes[i].tick)
        }
    }
       staves.sort(function(a,b){return a-b})
       tracks.sort(function(a,b){return a-b})
       ticks.sort(function(a,b){return a-b})
    
    var voices=[];  ///get unique voices per staff        
    for (var i in staves){
        var voic=[]            
        for (var n in Notes){                
            if(Notes[n].staff==staves[i]){                    
                if (!voic.some(function(x){return x==Notes[n].voice})){ 
                    voic.push(Notes[n].voice) 
                }
            }
        }            
        voic.sort();           
        voices.push(voic)
    }
    


    //console.log("staves : ", staves,"voices : ", voices[0],voices[1], "tracks : ",tracks,"levels : " ,levels[0],levels[1], levels[2]  )

   
    ///////////////////////////////////////////////////////
        var t1 = ticks[0];  // min tick
        var t2 = ticks[ticks.length-1]; //max tick 

    cursor.track=tracks[0]
    cursor.rewindToTick(t2)
    cursor.next()
    if (cursor.tick==0){  //check if end of track or staff
        cursor.rewindToTick(t2)
        var endOfMeasureTick=cursor.measure.lastSegment.tick
        var endOfStaffTick= curScore.lastSegment.tick
        if (endOfMeasureTick==endOfStaffTick){
            var t2=curScore.lastSegment.tick+1 
        }
        else{
            t2= cursor.measure.lastSegment.tick  //in case of end of voice but not staff
        }             
    }
    else{
        t2=cursor.tick      /////fix t2 to go till (end of last selected note)/(start of next note)
    }



    console.log("t1= ",t1, "t2= ",t2)       


    
    
    curScore.startCmd()
    /////////////////////////////////////////////////////////
    
        var notesDeleted=0
        for(var s=staves[0]; s<=staves[staves.length-1]+1; s++){
            
            for (var v=0; v<4; v++){
                var track=s*4+v
                cursor.track=track
                cursor.rewindToTick(t1)
                //if (voices[s].some(function(x){return x==v})){
                  //  var trackIdx= tracks.indexOf(track)
                   // console.log(levels[trackIdx])
                    while (cursor.segment && (cursor.tick < t2)) {   /// selects notes with same levels on the same track
                        var el= cursor.element
                        if(el.type == Element.CHORD) {
                            //var notePresent=0
                            for (var n= el.notes.length-1; n>=0; n--){   
                               /* if (el.notes[n].selected==true){
                                   notePresent++
                                   console.log("yes")
                                }
                                if (el.notes[n].selected==false) {
                                    if (n>0){
                                           console.log("not selected")                                
                                           el.remove(el.notes[n]) 
                                           return                                          
                                    }
                                
                                    if (n==0){                                 
                                      if (notePresent>0){ el.remove(el.notes[n])}
                                      if (notePresent==0) {removeElement(el)}
                                      console.log("last note")                                     
                                    }
                                  notesDeleted++                                  
                                }  */
                                console.log("n:  " + n)
                                if (el.notes[n].selected==true)    {curScore.selection.deselect(el.notes[n], true)  }
                                else {curScore.selection.select(el.notes[n], true)  } 
                            }
                        }
                        cursor.next()   
                    //}                                                
                }
                /*
                if (!voices[s].some(function(x){return x==v})){           /// if voice wasnt in selection but exists, delete it.            
                    while (cursor.segment && (cursor.tick < t2)) {   
                        var el= cursor.element
                        if(el.type == Element.CHORD) {                    
                            removeElement(el)
                            notesDeleted++
                            if(v!=0){
                                var el= cursor.element                                                
                                removeElement(el)
                                notesDeleted++
                            }                                
                        }
                        cursor.next()
                    }
                }
            */         
            }///end voices iteration
        }///end staves iteration

         
        cmd("delete")                      
        curScore.selection.selectRange(t1, t2, staves[0], staves[staves.length-1]+1);   
        
        cmd("copy");
        curScore.endCmd();
       
        cmd("undo");    
            

    
    
    }//end function copyselection
}//end musescore
