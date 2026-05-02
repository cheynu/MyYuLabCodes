function I = ReadJpegSEQ3(fileName,frame)
% -------------------------------------------------------------------------
% Read compressed or uncompressed monochrome NorPix image sequence in MATLAB.
% Reading window for compressed sequences requires a separate .idx file
% named as the source file (eg. test.seq.idx).
% 
% INPUTS
%    fileName:       String containing the full path to the sequence
%    frame:          1x1 double of the frame index
% OUTPUTS
%    I:              the image (matrix)
% 
% Last modified 2021.04.30 by Yue Huang
% Last modified 2025.04.16 by Jianing Yu (check frame location)

% Open the sequence and index files
fid = fopen(fileName, 'r', 'b');
if fid == -1
    error('Cannot open file: %s', fileName);
end

fidIdx = fopen([fileName '.idx'], 'r');
if fidIdx == -1
    fclose(fid);
    error('Cannot open index file: %s.idx', fileName);
end

endianType = 'ieee-le'; % Little-endian format

% Get file size to check for EOF
fseek(fid, 0, 'eof');
fileSize = ftell(fid);
fseek(fid, 0, 'bof');

% Determine total number of frames in .idx file
fseek(fidIdx, 0, 'eof');
idxSize = ftell(fidIdx);
totalFrames = floor((idxSize - 8) / 24); % Each frame entry is 24 bytes after header
fseek(fidIdx, 0, 'bof');

% Check if requested frame is valid
if frame < 1 || frame > totalFrames
    fclose(fidIdx);
    fclose(fid);
    I = [];
    warning('Frame %d is out of range (1 to %d). Returning empty image.', frame, totalFrames);
    return;
end

% Read frame using idx buffer size information
if frame == 1
    readStart = 1028;
    fseek(fidIdx, 8, 'bof');
    imageBufferSize = fread(fidIdx, 1, 'ulong', endianType);
else
    readStartIdx = frame * 24;
    fseek(fidIdx, readStartIdx, 'bof');
    readStart = fread(fidIdx, 1, 'uint64', endianType) + 4;
    imageBufferSize = fread(fidIdx, 1, 'ulong', endianType);
end

% Validate readStart and imageBufferSize
if isempty(readStart) || isempty(imageBufferSize)
    fclose(fidIdx);
    fclose(fid);
    I = [];
    warning('Invalid index data for frame %d. Returning empty image.', frame);
    return;
end

if readStart + imageBufferSize > fileSize
    fclose(fidIdx);
    fclose(fid);
    I = [];
    warning('Frame %d exceeds file size. Returning empty image.', frame);
    return;
end

% Seek to the frame position
status = fseek(fid, readStart, 'bof');
if status == -1
    fclose(fidIdx);
    fclose(fid);
    I = [];
    error('fseek failed for frame %d: Invalid offset.', frame);
end

% Read and decode the frame
JpegSEQ = fread(fid, imageBufferSize, 'uint8', endianType);
if isempty(JpegSEQ)
    fclose(fidIdx);
    fclose(fid);
    I = [];
    warning('Failed to read data for frame %d. Returning empty image.', frame);
    return;
end

I = uint8(py.cv2.imdecode(py.numpy.uint8(py.numpy.array(JpegSEQ)), uint8(0)));

% Close files
fclose(fidIdx);
fclose(fid);
end
