### Binary Search Tree: Insertion and Deletion


### Overview

A binary search tree (BST) is a tree-like data structure made of nodes that mantains a sorted list of numbers. Each node of a BST can have up to 2 children. Each node has a unique key which satisfy the following properties:

1) All nodes in the left subtree of a node contain values less than the node’s value.

2) All nodes in the right subtree of a node contain values greater than the node’s value.

The conditions above allow for fast lookups (searches), addition and removal of data items encapsulated in a node.

### Details

In order to get the algorithm of this 64-bit assembly language  correct (and bug free), a C program was written and debugged. Given below are the C implementations of the **insertNode** and **deleteNode** functions.

```C
    void insertNode(struct node **root, struct node *p)
    {
        struct node *currNode, *parentNode;

        parentNode = NULL;
        currNode = *root;
        while (currNode != NULL)  {
            parentNode = currNode;
            if (p->key < currNode->key) {
                currNode = currNode->left;
            }
            else {
                currNode = currNode->right;
            }
        }
        if (parentNode == NULL) {
            *root = p;            // tree was empty
        }
        else if (p->key < parentNode->key) {
            parentNode->left = p;
        }
        else {
            parentNode->right = p;
        }  
    }

    // Reference: weblink 2
    void deleteNode(struct node **root, int key) {

        struct node *curr = *root;
        struct node *parentNode = NULL;     // root of the main tree or subtree

        // Find the node to be deleted for the given key by moving down the tree.
        while (curr != NULL && curr->key != key) {
            parentNode = curr;
            if (key < curr->key) {
                curr = curr->left;
            }
            else {
                // key >= curr->key
                curr = curr->right;
            }
        } // while

        // If key is not present in BST, just return
        if (curr == NULL) {
            return;
        }

        if (curr->left == NULL || curr->right == NULL) {
            // One child or no children
            struct node *newNode = NULL;
            if (curr->left == NULL) {
                // No Left child
                newNode = curr->right;
            }
            else {
                // No Right child
                newNode = curr->left;
            }

            // Check if the node to be deleted is the root of the tree.
            if (parentNode == NULL) {
                free(curr);
                *root = newNode;
                return;
            }

            if (curr == parentNode->left) {
                parentNode->left = newNode;
            }
            else {
                parentNode->right = newNode;
            }
            free(curr);
        }
        else {
            // Two children
            struct node *successorParent = NULL;
            struct node *successor;
            // Find the successor node which has the minimum key in the right subtree
            // of the node to be deleted.
            successor = curr->right;
            while (successor->left != NULL) {
                successorParent = successor;
                successor = successor->left;
            }

            // Check if the parent node of the successor is the NULL or not.
            // If it isn't, then make the left child of its parent node equal to the
            // successor's right child. Otherwise, make the right child of the node
            // to be deleted equal to the right child of the successor.
            if (successorParent != NULL) {
                successorParent->left = successor->right;
            }
            else {
                // Special case: root node is modified (instead of being deleted.)
                // The contents of the root node (which does not have a parent node)
                // might be changed here.
                // On fall thru (after the instruction below), its key value is changed but it is not freed.
                // Its successor node is freed.
                curr->right = successor->right;
            }

            curr->key = successor->key;
            free(successor);
        }
    }
```

**Requirements:**

XCode 11.3

Can run on any 64-bit Intel macOS.

**Running on Linux**

This demo can be compiled and run under a command line prompt operating under 64-bit Intel-based Linux with a little modification.

Edit the source file (BinarySearchTree.s) by removing underscores from the function names.

Compile the source file with the gcc compiler.

    gcc BinarySearchTree.s -o bst -z noexecstack



**Web Resources**

1) https://www.programiz.com/dsa/binary-search-tree

2) https://www.enjoyalgorithms.com/blog/deletion-in-binary-search-tree

3) https://www.geeksforgeeks.org/dsa/binary-search-tree-data-structure/

