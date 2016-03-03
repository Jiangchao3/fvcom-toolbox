function write_FVCOM_river_ERSEM(RiverFile,RiverName,time,flux,temp,salt,N1_p,N3_n,N4_n,N5_s,O3_c,O3_bioalk,RiverInfo1,RiverInfo2)
% Write FVCOM-ERSEM 3.x netCDF river file
%
% function write_FVCOM_river(RiverFile,RiverName,time,flux,temp,salt,N1_p,N3_n,N4_n,N5_s,O3_c,O3_bioalk,RiverInfo1,RiverInfo2)
%
% DESCRIPTION:
%    Write river flux, temperature, and salinity to an FVCOM river file.
%    Flux, temperature and salinity must be calculated prior to being given
%    here as the raw values in the arrays are simply written out as is to
%    the NetCDF file.
%
% INPUT
%    RiverFile  : FVCOM 3.x NetCDF river forcing file
%    RiverName  : Name of the actual River
%    time       : Timestamp array in modified Julian day
%    flux       : Total river flux in m^3/s (dimensions [time, nRivernodes])
%    temp       : Temperature in C (dimensions [time, nRivernodes])
%    salt       : Salinity in PSU (dimensions [time, nRivernodes])
%    N1_p       : phosphate in umol/m^{3}
%    N3_n       : nitrate in umol/m^{3}
%    N4_n       : ammonia in umol/m^{3}
%    N5_s       : silicate in umol/m^{3}
%    O3_c       : dissolved inorganic carbon  in umol/m^{3}
%    O3_bioalk  : carbonate bioalkalinity  in umol/m^{3}
%    RiverInfo1 : Global attribute title of file
%    RiverInfo2 : Global attribute info of file
%
% OUTPUT:
%    FVCOM NetCDF river file with flux, temperature and salinity.
%
% EXAMPLE USAGE
%    write_FVCOM_river('tst_riv.nc', {'Penobscot'}, time, flux, ...
%        temp, salt, ...
%        N1_p, N3_n, N4_n, N5_s, O3_c, O3_bioalk, ...
%        'Penobscot Flux', 'source: USGS')
%
% Author(s):
%    Geoff Cowles (University of Massachusetts Dartmouth)
%    Pierre Cazenave (Plymouth Marine Laboratory)
%    Ricard Torres (Plymouth Marine Laboratory)
%
% Revision history
%   2013-03-21 Modified to take a list of river nodes rather than a single
%   river spread over multiple nodes. This means you have to scale your
%   inputs prior to using this function. This also means I have broken
%   backwards compatibility with the old way of doing it (i.e. this
%   function previously wrote only a single river's data but spread over a
%   number of nodes). I removed the sediment stuff as the manual makes no
%   mention of this in the river input file. Also added support for writing
%   to NetCDF using MATLAB's native tools.
%   2013-03-21 Transpose the river data arrays to the correct shape for the
%   NetCDF file.
%   2016-03-02 Update for use with FABM-ERSEM.
%
%==========================================================================

[~, subname] = fileparts(mfilename('fullpath'));

global ftbverbose
if ftbverbose
    fprintf('\nbegin : %s\n', subname)
end

[nTimes, nRivnodes] = size(flux);
if ftbverbose
    fprintf('# of river nodes: %d\n', nRivnodes);
    fprintf('# of time frames: %d\n', nTimes);
end

[year1, month1, day1, ~, ~, ~] = mjulian2greg(time(1));
[year2, month2, day2, ~, ~, ~] = mjulian2greg(time(end));
if ftbverbose
    fprintf('time series begins at:\t%04d %02d %02d\n', year1, month1, day1);
    fprintf('time series ends at:\t%04d %02d %02d\n', year2, month2, day2);
end
clear year? month? day?

%--------------------------------------------------------------------------
% dump to netcdf file
%--------------------------------------------------------------------------

% river node forcing
nc = netcdf.create(RiverFile, 'clobber');

% global variables
netcdf.putAtt(nc, netcdf.getConstant('NC_GLOBAL'), 'type', 'FVCOM RIVER FORCING FILE')
netcdf.putAtt(nc, netcdf.getConstant('NC_GLOBAL'), 'title', RiverInfo1)
netcdf.putAtt(nc, netcdf.getConstant('NC_GLOBAL'), 'info', RiverInfo2)
netcdf.putAtt(nc, netcdf.getConstant('NC_GLOBAL'), 'history', sprintf('File created using %s from the MATLAB fvcom-toolbox', subname))

% dimensions
namelen_dimid = netcdf.defDim(nc, 'namelen', 80);
rivers_dimid = netcdf.defDim(nc, 'rivers', nRivnodes);
time_dimid = netcdf.defDim(nc, 'time', netcdf.getConstant('NC_UNLIMITED'));
date_str_len_dimid = netcdf.defDim(nc, 'DateStrLen', 26);

% variables
river_names_varid = netcdf.defVar(nc, 'river_names', 'NC_CHAR', [namelen_dimid, rivers_dimid]);

time_varid = netcdf.defVar(nc, 'time', 'NC_FLOAT', time_dimid);
netcdf.putAtt(nc, time_varid, 'long_name', 'time');
netcdf.putAtt(nc, time_varid, 'units', 'days since 1858-11-17 00:00:00');
netcdf.putAtt(nc, time_varid, 'format', 'modified julian day (MJD)');
netcdf.putAtt(nc, time_varid, 'time_zone', 'UTC');

itime_varid = netcdf.defVar(nc, 'Itime', 'NC_INT', time_dimid);
netcdf.putAtt(nc, itime_varid, 'units', 'days since 1858-11-17 00:00:00');
netcdf.putAtt(nc, itime_varid, 'format', 'modified julian day (MJD)');
netcdf.putAtt(nc, itime_varid, 'time_zone', 'UTC');

itime2_varid = netcdf.defVar(nc, 'Itime2', 'NC_INT', time_dimid);
netcdf.putAtt(nc, itime2_varid, 'units', 'msec since 00:00:00');
netcdf.putAtt(nc, itime2_varid, 'time_zone', 'UTC');

times_varid = netcdf.defVar(nc,'Times','NC_CHAR',[date_str_len_dimid, time_dimid]);
netcdf.putAtt(nc, times_varid, 'time_zone','UTC');

river_flux_varid = netcdf.defVar(nc, 'river_flux', 'NC_FLOAT', [rivers_dimid, time_dimid]);
netcdf.putAtt(nc, river_flux_varid, 'long_name', 'river runoff volume flux');
netcdf.putAtt(nc, river_flux_varid, 'units', 'm^3s^-1');

river_temp_varid = netcdf.defVar(nc, 'river_temp', 'NC_FLOAT', [rivers_dimid, time_dimid]);
netcdf.putAtt(nc, river_temp_varid, 'long_name', 'river runoff temperature');
netcdf.putAtt(nc, river_temp_varid, 'units', 'Celsius');

river_salt_varid = netcdf.defVar(nc, 'river_salt', 'NC_FLOAT', [rivers_dimid, time_dimid]);
netcdf.putAtt(nc, river_salt_varid, 'long_name', 'river runoff salinity');
netcdf.putAtt(nc, river_salt_varid, 'units', 'PSU');

river_n1p_varid = netcdf.defVar(nc, 'N1_p', 'NC_FLOAT', [rivers_dimid, time_dimid]);
netcdf.putAtt(nc, river_n1p_varid, 'long_name', 'river phosphate concentrations');
netcdf.putAtt(nc, river_n1p_varid, 'units', 'mmolm^-3');

river_n3n_varid = netcdf.defVar(nc, 'N3_n', 'NC_FLOAT', [rivers_dimid, time_dimid]);
netcdf.putAtt(nc, river_n3n_varid, 'long_name', 'river Nitrate concentrations');
netcdf.putAtt(nc, river_n3n_varid, 'units', 'mmolm^-3');

river_n4n_varid = netcdf.defVar(nc, 'N4_n', 'NC_FLOAT', [rivers_dimid, time_dimid]);
netcdf.putAtt(nc, river_n4n_varid, 'long_name', 'river ammonium concentrations');
netcdf.putAtt(nc, river_n4n_varid, 'units', 'mmolm^-3');

river_n5s_varid = netcdf.defVar(nc, 'N5_s', 'NC_FLOAT', [rivers_dimid, time_dimid]);
netcdf.putAtt(nc, river_n5s_varid, 'long_name', 'river silicate concentrations');
netcdf.putAtt(nc, river_n5s_varid, 'units', 'mmolm^-3');

river_o3c_varid = netcdf.defVar(nc, 'O3_c', 'NC_FLOAT', [rivers_dimid, time_dimid]);
netcdf.putAtt(nc, river_o3c_varid, 'long_name', 'river dissolved inorganic carbon concentrations');
netcdf.putAtt(nc, river_o3c_varid, 'units', 'mmolm^-3');

river_o3bioalk_varid = netcdf.defVar(nc, 'O3_bioalk', 'NC_FLOAT', [rivers_dimid, time_dimid]);
netcdf.putAtt(nc, river_o3bioalk_varid, 'long_name', 'river alkalinity');
netcdf.putAtt(nc, river_o3bioalk_varid, 'units', 'mmolm^-3');

% end definitions
netcdf.endDef(nc);

% river names (must be 80 character strings)
rString = char();
for i = 1:nRivnodes
    % Left-aligned 80 character string.
    rString = [rString, sprintf('%-80s', RiverName{i})];
end
netcdf.putVar(nc, river_names_varid, rString);

% dump dynamic data
netcdf.putVar(nc, time_varid, 0, nTimes, time);
netcdf.putVar(nc, itime_varid, 0, nTimes, floor(time));
netcdf.putVar(nc, itime2_varid, 0, nTimes, mod(time, 1)*24*3600*1000);
netcdf.putVar(nc, river_flux_varid, flux');
netcdf.putVar(nc, river_temp_varid, temp');
netcdf.putVar(nc, river_salt_varid, salt');
netcdf.putVar(nc, river_n1p_varid, N1_p');
netcdf.putVar(nc, river_n3n_varid, N3_n');
netcdf.putVar(nc, river_n4n_varid, N4_n');
netcdf.putVar(nc, river_n5s_varid, N5_s');
netcdf.putVar(nc, river_o3c_varid, O3_c');
netcdf.putVar(nc, river_o3bioalk_varid, O3_bioalk');

% build the time string and output to NetCDF.
nStringOut = char();
[nYr, nMon, nDay, nHour, nMin, nSec] = mjulian2greg(time);
for tt = 1:nTimes
    nDate = [nYr(tt), nMon(tt), nDay(tt), nHour(tt), nMin(tt), nSec(tt)];
    nStringOut = [nStringOut, sprintf('%04i/%02i/%02i %02i:%02i:%02i       ', nDate)];
end
netcdf.putVar(nc, times_varid, nStringOut);

netcdf.close(nc);

if ftbverbose
    fprintf('end   : %s\n', subname)
end

