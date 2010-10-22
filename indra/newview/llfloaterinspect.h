/** 
* @file llfloaterinspect.h
* @author Cube
* @date 2006-12-16
* @brief Declaration of class for displaying object attributes
*
* $LicenseInfo:firstyear=2006&license=viewergpl$
* 
* Copyright (c) 2006-2010, Linden Research, Inc.
* 
* Second Life Viewer Source Code
* The source code in this file ("Source Code") is provided by Linden Lab
* to you under the terms of the GNU General Public License, version 2.0
* ("GPL"), unless you have obtained a separate licensing agreement
* ("Other License"), formally executed by you and Linden Lab.  Terms of
* the GPL can be found in doc/GPL-license.txt in this distribution, or
* online at http://secondlifegrid.net/programs/open_source/licensing/gplv2
* 
* There are special exceptions to the terms and conditions of the GPL as
* it is applied to this Source Code. View the full text of the exception
* in the file doc/FLOSS-exception.txt in this software distribution, or
* online at
* http://secondlifegrid.net/programs/open_source/licensing/flossexception
* 
* By copying, modifying or distributing this software, you acknowledge
* that you have read and understood your obligations described above,
* and agree to abide by those obligations.
* 
* ALL LINDEN LAB SOURCE CODE IS PROVIDED "AS IS." LINDEN LAB MAKES NO
* WARRANTIES, EXPRESS, IMPLIED OR OTHERWISE, REGARDING ITS ACCURACY,
* COMPLETENESS OR PERFORMANCE.
* $/LicenseInfo$
*/

#ifndef LL_LLFLOATERINSPECT_H
#define LL_LLFLOATERINSPECT_H

#include "llfloater.h"

//class LLTool;
class LLObjectSelection;
class LLScrollListCtrl;
class LLUICtrl;

class LLFloaterInspect : public LLFloater
{
	friend class LLFloaterReg;
public:

//	static void show(void* ignored = NULL);
	void onOpen(const LLSD& key);
	virtual BOOL postBuild();
	void dirty();
	LLUUID getSelectedUUID();
	virtual void draw();
	virtual void refresh();
//	static BOOL isVisible();
	virtual void onFocusReceived();
	void onClickCreatorProfile();
	void onClickOwnerProfile();
	void onSelectObject();
	LLScrollListCtrl* mObjectList;
protected:
	// protected members
	void setDirty() { mDirty = TRUE; }
	bool mDirty;

private:
	
	LLFloaterInspect(const LLSD& key);
	virtual ~LLFloaterInspect(void);
	// static data
//	static LLFloaterInspect* sInstance;

	LLSafeHandle<LLObjectSelection> mObjectSelection;
};

#endif //LL_LLFLOATERINSPECT_H
