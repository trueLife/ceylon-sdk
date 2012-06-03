import java.nio.file { JPath=Path,
                       FileSystems { defaultFileSystem=default },
                       Files { isReadable, isWritable, isExecutable, 
                               getFileStore } }
import ceylon.fs { ... }
import ceylon.fs.internal { Util { newPath, getLastModified,
                                   isDirectory, isRegularFile, isExisting,
                                   copyPath, deletePath, movePath, overwritePath,
                                   newDirectory, newFile } }

shared Path path(String pathString) {
    return ConcretePath(newPath(pathString));
}

shared Path[] roots {
    value sb = SequenceBuilder<Path>();
    value iter = defaultFileSystem.rootDirectories.iterator();
    while (iter.hasNext()) {
        sb.append(ConcretePath(iter.next()));
    }
    return sb.sequence;
}

JPath asJPath(String|Path path) {
    if (is ConcretePath path) {
        return path.jpath;
    }
    else {
        return newPath(path.string);
    }
}

class ConcretePath(jpath)
        extends Path() {
    shared JPath jpath;
    shared actual Path parent {
        return ConcretePath(jpath.parent);
    }
    shared actual Path childPath(String|Path subpath) {
        return ConcretePath(jpath.resolve(asJPath(subpath)));
    }
    shared actual Path siblingPath(String|Path subpath) {
        return ConcretePath(jpath.resolveSibling(asJPath(subpath)));
    }
    shared actual Path absolutePath {
        return ConcretePath(jpath.toAbsolutePath());
    }
    shared actual Path normalizedPath {
        return ConcretePath(jpath.normalize());
    }
    shared actual Boolean parentOf(Path path) {
        return asJPath(path).startsWith(jpath);
    }
    shared actual Boolean childOf(Path path) {
        return jpath.startsWith(asJPath(path));
    }
    shared actual Path relativePath(String|Path path) {
        return ConcretePath(this.jpath.relativize(asJPath(path)));
    }
    shared actual String string {
        return jpath.string;
    }
    shared actual Path[] elementPaths {
        value sb = SequenceBuilder<Path>();
        value iter = jpath.iterator();
        while (iter.hasNext()){
            sb.append(ConcretePath(iter.next()));
        }
        return sb.sequence;
    }
    shared actual String[] elements {
        value sb = SequenceBuilder<String>();
        value iter = jpath.iterator();
        while (iter.hasNext()){
            sb.append(iter.next().string);
        }
        return sb.sequence;
    }
    shared actual Boolean absolute {
        return jpath.absolute;
    }
    shared actual Comparison compare(Path other) {
        if (is ConcretePath other) {
            return jpath.compareTo(other.jpath)<=>0;
        }
        else {
            return string<=>other.string;
        }
    }
    shared actual Boolean equals(Object that) {
        if (is ConcretePath that) {
            return that.jpath==jpath;
        }
        else {
            return false;
        }
    }
    shared actual Integer hash {
        return jpath.hash;
    }
    shared actual Resource resource {
        abstract class ResourceWithPath() 
                satisfies Resource {
            shared actual Path path { 
                return ConcretePath(jpath); 
            }
            shared actual String string {
                return jpath.string;
            }
        }            
        if (isExisting(jpath)) {
            if (isRegularFile(jpath)) {
                object file 
                        extends ResourceWithPath() 
                        satisfies File {
                    shared actual File copy(Directory dir) {
                        value cp = copyPath(jpath, asJPath(dir.path));
                        if (is File file = ConcretePath(cp).resource) {
                            return file;
                        }
                        else {
                            throw Exception("copy failed");
                        }
                    }
                    shared actual File move(Directory dir) {
                        value mp = movePath(jpath, 
                                asJPath(dir.path).resolve(jpath.fileName));
                        if (is File file = ConcretePath(mp).resource) {
                            return file;
                        }
                        else {
                            throw Exception("move failed");
                        }
                    }
                    shared actual File overwrite(File file) {
                        value op = overwritePath(jpath, asJPath(file.path));
                        if (is File result = ConcretePath(op).resource) {
                            return result;
                        }
                        else {
                            throw Exception("overwrite failed");
                        }
                    }
                    shared actual File rename(Nil nil) {
                        value rp = movePath(jpath, asJPath(nil.path));
                        if (is File result = ConcretePath(rp).resource) {
                            return result;
                        }
                        else {
                            throw Exception("rename failed");
                        }
                    }
                    shared actual Nil delete() {
                        deletePath(jpath);
                        if (is Nil nil = ConcretePath(jpath).resource) {
                            return nil;
                        }
                        else {
                            throw Exception("delete failed");
                        }
                    }
                    shared actual Boolean readable {
                        return isReadable(jpath);
                    }
                    shared actual Boolean writable {
                        return isWritable(jpath);
                    }
                    shared actual Boolean executable {
                        return isExecutable(jpath);
                    }
                    shared actual Integer lastModifiedMilliseconds {
                        return getLastModified(jpath);
                    }
                    shared actual String name {
                        return jpath.fileName.string;
                    }
                    shared actual Store store {
                        return ConcreteStore(getFileStore(jpath));
                    }
                }
                return file;
            }
            else if (isDirectory(jpath)) {
                object dir 
                        extends ResourceWithPath() 
                        satisfies Directory {
                    shared actual Path[] childPaths {
                        value sb = SequenceBuilder<Path>();
                        for (s in jpath.toFile().list()) {
                            sb.append(ConcretePath(newPath(s)));
                        }
                        return sb.sequence;
                    }
                    shared actual Resource[] children {
                        return childPaths[].resource;
                    }
                    shared actual Nil delete() {
                        deletePath(jpath);
                        if (is Nil nil = ConcretePath(jpath).resource) {
                            return nil;
                        }
                        else {
                            throw Exception("delete failed");
                        }
                    }
                    shared actual File move(Directory dir) {
                        value mp = movePath(jpath, 
                                asJPath(dir.path).resolve(jpath.fileName));
                        if (is File file = ConcretePath(mp).resource) {
                            return file;
                        }
                        else {
                            throw Exception("move failed");
                        }
                    }
                    shared actual File rename(Nil nil) {
                        value rp = movePath(jpath, asJPath(nil.path));
                        if (is File result = ConcretePath(rp).resource) {
                            return result;
                        }
                        else {
                            throw Exception("rename failed");
                        }
                    }
                    shared actual Directory createDirectory(String|Path name) {
                        value d = newDirectory(jpath.resolve(asJPath(name)));
                        if (is Directory dir = ConcretePath(d).resource) {
                            return dir;
                        }
                        else {
                            throw;
                        }
                    }
                    shared actual File createFile(String|Path name) {
                        value f = newFile(jpath.resolve(asJPath(name)));
                        if (is File file = ConcretePath(f).resource) {
                            return file;
                        }
                        else {
                            throw;
                        }
                    }
                }
                return dir;
            }
            else {
                throw;
            }
        }
        else {
            object nil extends ResourceWithPath()
                    satisfies Nil {
                shared actual Directory createDirectory() {
                    value d = newDirectory(jpath);
                    if (is Directory dir = ConcretePath(d).resource) {
                        return dir;
                    }
                    else {
                        throw;
                    }
                }
                shared actual File createFile() {
                    value f = newFile(jpath);
                    if (is File file = ConcretePath(f).resource) {
                        return file;
                    }
                    else {
                        throw;
                    }
                }
            }
            return nil;
        }
    }
}