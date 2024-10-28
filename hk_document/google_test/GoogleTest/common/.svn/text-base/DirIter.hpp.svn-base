#pragma once
#include <vector>
#include <string>

using namespace std;

class DirIter_Data{
	friend class DirIter;
	HANDLE hff;
	BOOL ff_result;

	int use;

	DirIter_Data(const wstring& aPath, WIN32_FIND_DATAW& wfd):hff(FindFirstFileW(aPath.c_str(), &wfd)), ff_result(FALSE), use(1){
		if(valid()) ff_result = TRUE;
	}

	~DirIter_Data(){
		if(valid()){
			BOOL ret = FindClose(hff);
			if(!ret){
				throw std::runtime_error("FindClose return FALSE");
			}
		}
	}

	bool valid(){
		return hff!=INVALID_HANDLE_VALUE;
	}

	void nextItem(WIN32_FIND_DATAW& wfd){
		ff_result = FindNextFileW(hff, &wfd);
	}

	bool hasItem(){
		return valid() && ff_result;
	}
};

class DirIter{
	WIN32_FIND_DATAW wfd;
	DirIter_Data *data;

	wstring cur_dir;
	wstring filter;

	wstring crack_path(const wstring& aPath, wstring& dir, wstring& filter){
		size_t pos = aPath.find_last_of(L'\\');
		if(pos==wstring::npos){
			dir = aPath + L"\\";
			filter = L"*";
		}else if(pos==(aPath.size()-1)){
			dir = aPath;
			filter = L"*";
		}else{
			dir = aPath.substr(0,pos+1);
			filter = aPath.substr(pos+1);
		}
		wstring p = dir;
		p+=filter;
		return p;
	}

public:
	DirIter(const wstring& aPath){
		const wstring fixedPath = crack_path(aPath, cur_dir, filter);
		data = new DirIter_Data(fixedPath, wfd);
	}

	DirIter(const DirIter& di): data(di.data), wfd(di.wfd), cur_dir(di.cur_dir), filter(di.filter){
		++data->use;
	}

	DirIter& operator=(const DirIter& di){
		DirIter_Data* p = data;
		++di.data->use;
		data = di.data;
		wfd = di.wfd;
		cur_dir = di.cur_dir;
		filter = di.filter;
		--p->use;
		return *this;
	}

	virtual ~DirIter(){
		if(--data->use==0){
			delete data;
		}

	}

	operator bool(){
		return data->hasItem();
	}

	bool isDir(){
		if(wfd.dwFileAttributes&FILE_ATTRIBUTE_DIRECTORY){
			return true;
		}else{
			return false;
		}
	}

	const wstring operator*(){
		return wfd.cFileName;
	}

	const wstring& curDir(){
		return cur_dir;
	}

	DirIter& operator++(){
		data->nextItem(wfd);
		return *this;
	}

	DirIter operator++(int){
		DirIter c = *this;
		data->nextItem(wfd);
		return c;
	}
};

class DirIter2{
	vector<DirIter> stack;
public:
	DirIter2(const wstring& aPath){
		stack.push_back(aPath);
	}

	const wstring operator*(){
		return *stack.back();
	}

	DirIter2& operator++(){
		wstring curItem = *stack.back();
		if(stack.back().isDir() && curItem!=L"." && curItem!=L".."){
			DirIter& di = stack.back();
			wstring fullpath = di.curDir() + *di + L"\\*";
			stack.push_back(fullpath);
		}else{
			bool shift = false;
			do{
				shift = false;
				++stack.back();
				while(!stack.back() && stack.size()>1){
					shift = true;
					stack.pop_back();
				}
			}while(shift);
		}
		return *this;
	}

	operator bool(){
		return stack.size()>1 || stack.back();
	}

	bool isDir(){
		return stack.back().isDir();
	}

	const wstring& curDir(){
		return stack.back().curDir();
	}

	const size_t curDepth(){
		return stack.size();
	}
};
