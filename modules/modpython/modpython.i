/*
 * Copyright (C) 2004-2012  See the AUTHORS file for details.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 as published
 * by the Free Software Foundation.
 */

%module znc_core %{
#include <utility>
#include "../include/znc/Utils.h"
#include "../include/znc/Config.h"
#include "../include/znc/Socket.h"
#include "../include/znc/Modules.h"
#include "../include/znc/Nick.h"
#include "../include/znc/Chan.h"
#include "../include/znc/User.h"
#include "../include/znc/IRCNetwork.h"
#include "../include/znc/Client.h"
#include "../include/znc/IRCSock.h"
#include "../include/znc/Listener.h"
#include "../include/znc/HTTPSock.h"
#include "../include/znc/Template.h"
#include "../include/znc/WebModules.h"
#include "../include/znc/znc.h"
#include "../include/znc/Server.h"
#include "../include/znc/ZNCString.h"
#include "../include/znc/FileUtils.h"
#include "../include/znc/ZNCDebug.h"
#include "../include/znc/ExecSock.h"
#include "../include/znc/Buffer.h"
#include "modpython/module.h"

#include "modpython/ret.h"

#define stat struct stat
using std::allocator;
%}

%apply long { off_t };

%begin %{
#include "znc/zncconfig.h"
%}

%include <pyabc.i>
%include <typemaps.i>
%include <stl.i>
%include <std_list.i>

namespace std {
	template<class K> class set {
		public:
		set();
		set(const set<K>&);
	};
}

%include "modpython/cstring.i"
%template(_stringlist) std::list<CString>;

%typemap(out) CModules::ModDirList %{
	$result = PyList_New($1.size());
	if ($result) {
		for (size_t i = 0; !$1.empty(); $1.pop(), ++i) {
			PyList_SetItem($result, i, Py_BuildValue("ss", $1.front().first.c_str(), $1.front().second.c_str()));
		}
	}
%}

%template(VIRCNetworks) std::vector<CIRCNetwork*>;
%template(VChannels) std::vector<CChan*>;
%template(MNicks) std::map<CString, CNick>;

%typemap(in) CString& {
	String* p;
	int res = SWIG_IsOK(SWIG_ConvertPtr($input, (void**)&p, SWIG_TypeQuery("String*"), 0));
	if (SWIG_IsOK(res)) {
		$1 = &p->s;
	} else {
		SWIG_exception_fail(SWIG_ArgError(res), "need znc.String object as argument $argnum $1_name");
	}
}

%typemap(out) CString&, CString* {
	if ($1) {
		$result = CPyRetString::wrap(*$1);
	} else {
		$result = Py_None;
		Py_INCREF(Py_None);
	}
}

/*TODO %typemap(in) bool& to be able to call from python functions which get bool& */

%typemap(out) bool&, bool* {
	if ($1) {
		$result = CPyRetBool::wrap(*$1);
	} else {
		$result = Py_None;
		Py_INCREF(Py_None);
	}
}

#define u_short unsigned short
#define u_int unsigned int
#include "../include/znc/ZNCString.h"
%include "../include/znc/defines.h"
%include "../include/znc/Utils.h"
%include "../include/znc/Config.h"
%include "../include/znc/Csocket.h"
%template(ZNCSocketManager) TSocketManager<CZNCSock>;
%include "../include/znc/Socket.h"
%include "../include/znc/FileUtils.h"
%include "../include/znc/Modules.h"
%include "../include/znc/Nick.h"
%include "../include/znc/Chan.h"
%include "../include/znc/User.h"
%include "../include/znc/IRCNetwork.h"
%include "../include/znc/Client.h"
%include "../include/znc/IRCSock.h"
%include "../include/znc/Listener.h"
%include "../include/znc/HTTPSock.h"
%include "../include/znc/Template.h"
%include "../include/znc/WebModules.h"
%include "../include/znc/znc.h"
%include "../include/znc/Server.h"
%include "../include/znc/ZNCDebug.h"
%include "../include/znc/ExecSock.h"
%include "../include/znc/Buffer.h"

%include "modpython/module.h"

/* Really it's CString& inside, but SWIG shouldn't know that :) */
class CPyRetString {
	CPyRetString();
public:
	CString s;
};

%extend CPyRetString {
	CString __str__() {
		return $self->s;
	}
};

%extend String {
	CString __str__() {
		return $self->s;
	}
};

class CPyRetBool {
	CPyRetBool();
	public:
	bool b;
};

%extend CPyRetBool {
	bool __bool__() {
		return $self->b;
	}
}

%extend CModule {
	CString __str__() {
		return $self->GetModName();
	}
	MCString_iter BeginNV_() {
		return MCString_iter($self->BeginNV());
	}
	bool ExistsNV(const CString& sName) {
		return $self->EndNV() != $self->FindNV(sName);
	}
}

%extend CModules {
	void push_back(CModule* p) {
		$self->push_back(p);
	}
	bool removeModule(CModule* p) {
		for (CModules::iterator i = $self->begin(); $self->end() != i; ++i) {
			if (*i == p) {
				$self->erase(i);
				return true;
			}
		}
		return false;
	}
}

%extend CUser {
	CString __str__() {
		return $self->GetUserName();
	}
	CString __repr__() {
		return "<CUser " + $self->GetUserName() + ">";
	}
	std::vector<CIRCNetwork*> GetNetworks_() {
		return $self->GetNetworks();
	}
};

%extend CIRCNetwork {
	CString __str__() {
		return $self->GetName();
	}
	CString __repr__() {
		return "<CIRCNetwork " + $self->GetName() + ">";
	}
	std::vector<CChan*> GetChans_() {
		return $self->GetChans();
	}
}

%extend CChan {
	CString __str__() {
		return $self->GetName();
	}
	CString __repr__() {
		return "<CChan " + $self->GetName() + ">";
	}
	std::map<CString, CNick> GetNicks_() {
		return $self->GetNicks();
	}
};

%extend CNick {
	CString __str__() {
		return $self->GetNick();
	}
	CString __repr__() {
		return "<CNick " + $self->GetHostMask() + ">";
	}
};

/* To allow module-loaders to be written on python.
 * They can call CreatePyModule() to create CModule* object, but one of arguments to CreatePyModule() is "CModule* pModPython"
 * Pointer to modpython is already accessible to python modules as self.GetModPython(), but it's just a pointer to something, not to CModule*.
 * So make it known that CModPython is really a CModule.
 */
class CModPython : public CModule {
private:
	CModPython();
	CModPython(const CModPython&);
	~CModPython();
};

/* Web */

%template(StrPair) std::pair<CString, CString>;
%template(VPair) std::vector<pair<CString, CString> >;
typedef std::vector<std::pair<CString, CString> > VPair;
%template(VWebSubPages) std::vector<TWebSubPage>;

%inline %{
	void VPair_Add2Str_(VPair* self, const CString& a, const CString& b) {
		self->push_back(std::make_pair(a, b));
	}
%}

%extend CTemplate {
	void set(const CString& key, const CString& value) {
		(*$self)[key] = value;
	}
}

%inline %{
	TWebSubPage CreateWebSubPage_(const CString& sName, const CString& sTitle, const VPair& vParams, unsigned int uFlags) {
		return new CWebSubPage(sName, sTitle, vParams, uFlags);
	}
%}

/* vim: set filetype=cpp noexpandtab: */
