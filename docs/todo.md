- intraday use cases
  - data items
    - fetched (raw) intraday intervals
    - processed (monthly) intraday data files
  - steps
    - delete fetched (raw) intraday intervals directory
    - if no processed files exist
      - just start downloading from now backwards
      - process data after downloading all into moonly files
    - if any processed files exist
      - determine existing start date, use earliest timestamp in earliest processed intraday data file
      - if force re-check start date flag is set
        - fetch data around existing start date, see if there is any date change
        - if change, delete all processed files, and start downloading all again
        - if no change, just continue
      - determine last downloaded date
      - download from now to last downloaded date and merge with existing data







- getting start date
  - if no files present
    - start with
      - from 2000-01-01 00:00:00
      - from 2010-01-01 00:00:00
    - if both present
      - go decade before
      - no need to re-fetch later date, as it was alredy fetched in previous step
    - if none present
      - go decade later
      - no need to re-fetch earlier date, as it was alredy fetched in previous step
    - if only one present
      - do in loop
        - bisect the date between that date and now
        - if file is empty
          - new range is the mid date to high date
        - else
          - new range is low date to mid date
          - steps until low and high date have same start timestamp







- process intraday data
  - get all files
    - each file is in csv format
    - Timestamp,Gmtoffset,Datetime,Open,High,Low,Close,Volume
    - ensure Gmtoffset is 0, throw error if not
  - parse all files
    - put data in an array of six-tuples or hashes if not too slow
      - timestamp
      - open
      - high
      - low
      - close
      - volume
    - have the first and last timestamps handy
  - find data range
    - start - first entry of first file
    - end - last entry of last file
  <!-- - create a list of output file intervals
    - later on, we will be creating one file per interval
    - in our case, one file per month, format YYYY-MM.csv
  - for each interval
    - find input data files (their parsed data) that overlap with the interval
    - for each overlapping input file data
      - find data points that fall within the interval
        - use binary search to find start and end indices
      - if first input file for interval, just copy data rows
      - else
        - find index in current output data where the data from new input file should be inserted
          - use binary search to find insertion index
        - just crop old data after that index, and append new data -->
  - merge data from all files
    - apply data from first file directly
    - for each subsequent file
      - first check whether first timestamp is greater than last timestamp in merged data
        - if yes
          - just append all data
        - else
          - find insertion index using binary search
          - crop old data after that index, and append new data
    - consider storing this intermediate result on disk, for quicker future updates
      - but for now, we will keep it in memory only
  - apply splits
    - prepare splits
      - read splits data json
      - calculate compound split factor for each segment
        - segment is from one split date (inclusive) to next split date (exclusive)
      - get timestamp for each segment start (or nil for first segment)
      - store segments in an array
    - if splits are empty array, you are done
    - have current split segment index, starting at first segment
    - for each data point in merged data
      - while timestamp >= cssi->timestamp
        - move to next split segment index
      - if cssi is out of bounds
        - you are done (factor is 1), break
      - you are in the segment with such factor (before the split specified by that timestamp)
      - ohlc divide by that factor
      - volume multiply by that factorı

