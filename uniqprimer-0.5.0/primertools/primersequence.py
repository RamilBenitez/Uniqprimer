'''
Created on Jan 1, 2011

@author: John L. Herndon
@contact: herndon@cs.colostate.edu
@organization: Colorado State University
@group: Computer Science Department, Asa Ben-Hur's laboratory 
'''

from . import utils

class PrimerSequence( object ):
    """
    record sequence data, and store matched parts of the sequence 
    """
    
    def __init__( self, seqID, seqLength, sequence ):
        #an unmatched sub-sequence that starts at 0 goes until the end of the the sequence, to start out with.
        
        self.seqID = seqID
        self.seqLength = seqLength
        self.matchedSubSequences = [ ] 
        self.sequence = sequence
        
    def addMatch( self, match ):
        """
        Input: a utils.Match object
        Removes the matched sequence from the list of valid sequence data
        """
        
        self.matchedSubSequences.append( ( match.start, match.end ) )
    
    def findNonMatchedIndices( self ):
        # Kept for API compatibility; returns sorted indices efficiently using intervals
        utils.logMessage("PrimerSequence::findValidIndices( )", "getting unmatched sequence indices" )
        utils.logMessage( "PrimerSequence::findValidIndices( )", "there are {0} excluded sequences for {1}".format( len( self.matchedSubSequences ), self.seqID ) )
        excluded = sorted(self.matchedSubSequences)
        indices = []
        prev_end = 0
        for start, end in excluded:
            utils.logMessage("PrimerSequence::findValidIndices( )", f"removing exclude sequence {start} - {end}")
            if start > prev_end:
                indices.extend(range(prev_end, start))
            prev_end = max(prev_end, end)
        indices.extend(range(prev_end, self.seqLength))
        utils.logMessage("PrimerSequence::findValidIndices( )", "{0} unique indices".format( len( indices ) ) )
        return indices

    def findNonMatchedIndexSequences( self, indices ):
        utils.logMessage("PrimerSequence::findValidIndexSequences( )", "getting sequences from unique indices" )
        sequences = [ ]
        curSeq = [ ]
        for index in indices:
            if len( curSeq ) == 0:
                curSeq.append( index )
            elif index == curSeq[ -1 ] + 1:
                curSeq.append( index )
            else:
                sequences.append( curSeq )
                curSeq = [ ]
        sequences.append( curSeq )
        utils.logMessage("PrimerSequence::findValidIndexSequences( )", "{0} sequences found".format( len( sequences ) ) )
        return sequences


    def getNonMatchedSubSequences( self, minLength = 100 ):
        """
        Get all valid sub sequences after removing matches using interval arithmetic.
        Avoids building large index sets for performance.
        """
        utils.logMessage("PrimerSequence::getNonMatchedSubSequences( )", "finding valid sub sequences for {0}".format( self.seqID ) )
        utils.logMessage( "PrimerSequence::findValidIndices( )", "getting unmatched sequence indices" )
        utils.logMessage( "PrimerSequence::findValidIndices( )", "there are {0} excluded sequences for {1}".format( len( self.matchedSubSequences ), self.seqID ) )

        excluded = sorted(self.matchedSubSequences)
        seqStr = str(self.sequence)
        subSequences = []
        prev_end = 0
        total_unique = 0

        for start, end in excluded:
            utils.logMessage("PrimerSequence::findValidIndices( )", f"removing exclude sequence {start} - {end}")
            if start > prev_end:
                length = start - prev_end
                total_unique += length
                if length >= minLength:
                    subSequences.append(seqStr[prev_end:start])
            prev_end = max(prev_end, end)

        if self.seqLength > prev_end:
            length = self.seqLength - prev_end
            total_unique += length
            if length >= minLength:
                subSequences.append(seqStr[prev_end:self.seqLength])

        utils.logMessage("PrimerSequence::findValidIndices( )", "{0} unique indices".format(total_unique))
        utils.logMessage("PrimerSequence::findValidIndexSequences( )", "getting sequences from unique indices")
        utils.logMessage("PrimerSequence::findValidIndexSequences( )", "{0} sequences found".format(len(subSequences)))
        return subSequences
    
    def getMatchedSubSequences( self, minLength = 100 ):
        utils.logMessage("PrimerSequence::getMatchedSubSequences( )", "finding valid sub sequences for {0}".format( self.seqID ) )
        
        returnValue = [ ]
        for match in self.matchedSubSequences:
            subSequence = self.sequence[ match[ 0 ]:match[ 1 ] ]
            
            if len( subSequence ) >= minLength :
                returnValue.append( subSequence )
            
        return returnValue
            
                
         
        
        
        
        
        
        
    