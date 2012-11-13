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

class UTComp_ShockProjectile extends ShockProjectile;

event TakeDamage( int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType)
{
    local UTComp_PRI uPRI;
    if (EventInstigator != None && EventInstigator.Controller!=None)
        uPRI=class'UTComp_Util'.static.GetUTCompPRIFor(EventInstigator.Controller);

    if (DamageType == ComboDamageType)
    {
        Instigator = EventInstigator;
        SuperExplosion();

        if(uPRI != None)
        {
            uPRI.NormalWepStatsPrim[0]+=1;
	        uPRI.NormalWepStatsAlt[10]-=1;
	        uPRI.NormalWepStatsPrim[10]-=1;
	    }
        if( EventInstigator.Weapon != None )
        {
			EventInstigator.Weapon.ConsumeAmmo(0, ComboAmmoCost, true);
            Instigator = EventInstigator;
        }
    }
}

defaultproperties
{
}
