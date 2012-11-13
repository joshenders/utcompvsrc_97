/* UTComp - UT2004 Mutator
Copyright (C) 2004-2005 Aaron Everitt & Joël Moffatt

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA. */

//-----------------------------------------------------------
//      edited spinnywep so it looks right even if the
//      player is not facing at pitch/roll=0 for BSkins
//      Menu in utcomp vSrc
//-----------------------------------------------------------
class UTComp_SpinnyWeap extends SpinnyWeap;

function Tick(float Delta)
{
	local vector X,Y,Z;
    local vector X2,Y2;
    local rotator R2;
    local vector  V;
    local rotator R;

	R = Rotation;

    //changed from SpinnyWeap so that it rotates around
    //the players viewing direction, not just absolute
    R2.Yaw = Delta * SpinRate/Level.TimeDilation;
    GetAxes(R,X,Y,Z);
    V=vector(R2);
    X2=V.X*X + V.Y*Y;
    Y2=V.X*Y - V.Y*X;
    R2=OrthoRotation(X2,Y2,Z);

    SetRotation(R2);

	CurrentTime += Delta/Level.TimeDilation;

	// If desired, play some random animations
	if(bPlayRandomAnims && CurrentTime >= NextAnimTime)
	{
		PlayNextAnim();
	}
}

DefaultProperties
{

}
