import { auth } from './firebase';
import { createUserWithEmailAndPassword, signInWithEmailAndPassword, signOut, onAuthStateChanged, User } from 'firebase/auth';

export const registerWithEmail = (email: string, password: string) => createUserWithEmailAndPassword(auth, email, password);
export const signInWithEmail = (email: string, password: string) => signInWithEmailAndPassword(auth, email, password);
export const signOutUser = () => signOut(auth);
export const onAuthStateChangedListener = (cb: (user: User | null) => void) => onAuthStateChanged(auth, cb);
export const getIdToken = async () => (await auth.currentUser?.getIdToken()) ?? '';