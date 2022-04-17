% clear;clc;close all
%% Put the code you developed last week about drawing an aircraft below
clear;clc;close all
% parameters of the aircraft model
fuse_l1=1.5; % center of mass to tip of fuselage
fuse_l2=1; % center of mass to widest part of fuselage
fuse_l3=5; % center of mass to back of fuselage
fuse_h=1;
fuse_w=1;
wing_l=2; % length of wing along fuselage
wing_w=6; % wingspan
tail_h=1;
tailwing_l=1;
tailwing_w=3;

% Define the vertices (physical location of vertices)
  V = [1.5 0 0; 1 0.5 -0.5; 1 -0.5 -0.5; 1 -0.5 0.5; 1 0.5 0.5; -5 0 0; 0 3 0; -2 3 0; -2 -3 0; 0 -3 0; -4 1.5 0; -5 1.5 0; -5 -1.5 0; -4 -1.5 0; -4 0 0; -5 0 -1]; % 16 vertices totally
% define surfaces as a list of numbered vertices
  F = [1 1 2 3;1 1 3 4;1 1 4 5;1 1 2 5;2 3 6 6;3 4 6 6;4 5 6 6;2 5 6 6; 7 8 9 10;11 12 13 14;15 16 6 6];
% define colors for each face    
  myred = [1, 0, 0];
  mygreen = [0, 1, 0];
  myblue = [0, 0, 1];
  myyellow = [1, 1, 0];
  mycyan = [0, 1, 1];

  colors = [...
    mygreen;...  % front top
    mycyan;...  % front left
    myblue;...  % front bottom
    mycyan;...  % front right 
    mygreen;...  % main top 
    mycyan;...  % main left
    myblue;...  % main bottom 
    mycyan;...  % main right
    myred;...  % wings
    myred;...  % tailwing
    myyellow;...  % tailfin
    ];
% transform vertices from NED to XYZ (for matlab rendering)
R = [0, 1, 0;...
      1, 0, 0;...
      0, 0, -1];
V1 = V*R;
handle = patch('Vertices', V1, 'Faces', F,'FaceVertexCData',colors,'FaceColor','flat');
title('Spacecraft')
xlabel('East')
ylabel('North')
zlabel('-Down')
hold on
%% Machine-user interface to ask for the angles of phi, theta and psi
prompt = '30*pi/180 ';
phi = input(prompt);
prompt = '0 ';
theta = input(prompt);
prompt = '0 ';
psi = input(prompt);
%% rotation matrix
% Implement the three rotation matrices 
R_roll = [1 0 0; 0 cos(phi) sin(phi); 0 -sin(phi) cos(phi)];
R_pitch = [cos(theta) 0 -sin(theta); 0 1 0; sin(theta) 0 cos(theta)];
R_yaw = [cos(psi) sin(psi) 0; -sin(psi) cos(psi) 0; 0 0 1];
V = (R_roll* R_pitch*R_yaw * V')';
%% transform vertices from NED to XYZ (for matlab rendering)
R = [...
      0, 1, 0;...
      1, 0, 0;...
      0, 0, -1;...
      ];
V = V*R;
%% redraw 
set(handle,'Vertices',V,'Faces',F);