/*
struct node {
     long data;             # double as key
     struct node* left;
     struct node* right;
 };
 */
key      = 0
left     = 8
right    = 16
nodeSize = 24
NULL     = 0L

# Data section starts here

    .data
    .p2align    4, 0x90

rootNode:
    .quad    NULL       # stores ptr to root node


# array of long integers (on macOS these are 8 bytes each)
array:
    .quad   8, 3, 1, 6, 7, 10, 14, 4

fmtStr:
    .asciz    "%lld "

newline:
    .asciz "\n"

# Assembly code starts here
    .text
    .global _main, _createNode, _insertNode, _printTree, _deleteNode
    .extern _malloc, _printf, _free
    .p2align    4, 0x90

_main:
    subq    $16+8, %rsp                 # 3 locals
    movq    %r12, (%rsp)                # counter

.forLoop:
    cmpl    $8, %r12d                   # is i<8?
    jge     1f

    leaq    array(%rip), %rcx
    movq    (%rcx, %r12, 8), %rdi       # array(i)
    callq   _createNode

    movq    %rax, %rsi                  # ptr to newly-created node
    leaq    rootNode(%rip), %rdi        # rdi is never NULL
    callq   _insertNode
    addl    $1, %r12d                   # i++
    jmp     .forLoop

1:
    callq   _printTree

# Test deletion

    leaq    rootNode(%rip), %rdi
    movq    $7, %rsi
    callq   _deleteNode
    callq   _printTree

    leaq    rootNode(%rip), %rdi
    movq    $6, %rsi
    callq   _deleteNode
    callq   _printTree
    addq    $16+8, %rsp

    xorq    %rax, %rax
    ret

    .global _createNode
    .p2align    4, 0x90
#================================================
# struct node* createNode(long data)
_createNode:

    subq    $8, %rsp                    # align on a 16-byte boundary
    movq    %r12, (%rsp)                # callee-saved reg
    movq    %rdi, %r12                  # data

    movq     $nodeSize, %rdi
    callq    _malloc
    # rax has pointer to memblock
    movq     %r12, key(%rax)            # node->data = data
    movq     $NULL, %r12
    movq     %r12, left(%rax)           # node->left = NULL
    movq     %r12, right(%rax)          # node->right = NULL

    movq     (%rsp), %r12
    addq     $8, %rsp
    ret
#================================================
    .global _insertNode
    .p2align    4, 0x90
# void insertNode(struct node** root, struct node* p);
# Inputs:
# rdi - address of pointer to root (Never NULL)
# rsi - pointer to node to be inserted (p)
_insertNode:
# Since this is a leaf node, we may use the registers
#   rax, rcx, rdx, r8 and r9
# Also on entry, it is not necessary to align the
# stack on a 16-byte boundary.
# Usage:
# rax - scratch
# r8  - currNode
# r9  - parentNode

    movq    $NULL, %r9                  # parentNode = NULL
    movq    (%rdi), %r8                 # currNode = *root

.whileLoop:
    cmpq    $NULL, %r8                  # while currNode != NULL
    je      .exitWhile

    movq    %r8, %r9                    # parentNode = currNode
    movq    key(%rsi), %rax             # p->key
    cmpq    key(%r8), %rax              # if (p->key < currNode->key)
    jge     .greaterThan
# less than
    movq    left(%r8), %r8              # then currNode = currNode->left
    jmp     .whileLoop
# greater or equal
.greaterThan:
    movq    right(%r8), %r8             # currNode = currNode->right
    jmp     .whileLoop

.exitWhile:
    cmpq    $NULL, %r9                  # if parentNode == NULL
    jne     1f
    movq    %rsi, (%rdi)                # then *root = p
    jmp     3f
1:
    movq    key(%rsi), %rcx             # p->key
    cmpq    key(%r9), %rcx              # if (p->key < parentNode->key)
    jge     2f
    movq    %rsi, left(%r9)             # then parentNode->left = p
    jmp     3f
2:
# greater or equal
    movq    %rsi, right(%r9)            # parentNode->right  = p

3:
    ret

#================================================
    .global _printTree
    .p2align    4, 0x90
_printTree:
    push    %rbp
    movq     %rsp, %rbp

    leaq    rootNode(%rip), %rdi
    movq    (%rdi), %rdi
    movb    $0, %al
    callq   _treeprint
    movb    $0, %al
    leaq     newline(%rip), %rdi
    movb     $0, %al
    call    _printf

    leave
    ret

#================================================
    .global _treeprint
    .p2align    4, 0x90
# void treeprint(struct node *p);
_treeprint:
# Recursive inorder print function
# Entry
#    rdi    -    address of root (which is never NULL)
# Trashed
#    rax    -   scratch reg
#    rdi    -   curr node (on entry root node)
#    rsi    -   scratch reg
# Non-leaf function

    push    %rbp
    movq     %rsp, %rbp
    subq     $16, %rsp

    cmpq    $NULL, %rdi                 # if p != NULL
    je      1f
    movq    %rdi, (%rsp)                #  save temporarily
    movq    left(%rdi), %rdi
    callq   _treeprint                  # treeprint(p->left)
    movq    (%rsp), %rax
    movq    key(%rax), %rsi             # printf("%lld ", p->data)
    leaq    fmtStr(%rip), %rdi
    movb    $0, %al
    call    _printf
    movq    (%rsp), %rax
    movq    right(%rax), %rdi           # treeprint(p->right)
    call    _treeprint
1:
    leave
    ret

    .global _deleteNode
    .p2align    4, 0x90

#================================================
# void deleteNode(struct node **root, long key)
_deleteNode:
# Inputs:
# rdi - root
# rsi - key
# Non-leaf function
# Register usage:
# rbp - rootNode
# rbx - currNode
# r12 - parentNode
# r13 - newNode
# r14 - successorParent
# r15 - successor

    subq    $48+8, %rsp
    movq    %rbp, (%rsp)
    movq    %rbx, 8(%rsp)
    movq    %r12, 16(%rsp)
    movq    %r13, 24(%rsp)
    movq    %r14, 32(%rsp)
    movq    %r15, 40(%rsp)

    movq    %rdi, %rbp              # holds the pointer to the pointer to root node
    movq    (%rdi), %rbx            # currNode = *root
    movq    $NULL, %r12             # parentNode = NULL
.while:
    cmpq    $NULL, %rbx             # is currNode == NULL?
    je      exitWhile
    cmpq    %rsi, key(%rbx)         # is currNode->key != key?
    je      exitWhile
    movq    %rbx, %r12
    cmpq    key(%rbx), %rsi         # is key >= currNode->key?
    jge     .right
    movq    left(%rbx), %rbx        # currNode = currNode->left
    jmp     .while
.right:
    movq    right(%rbx), %rbx       # currNode = currNode->right
    jmp     .while

exitWhile:

    cmpq    $NULL, %rbx             # is currNode == NULL?
    jne     .keyFound
    jmp     .exitDelete             # yes, key is not found.

.keyFound:
# Check if there is no or one child
# currNode->left == NULL || currNode->right == NULL
    cmpq    $NULL, left(%rbx)       # is currNode->left == NULL?
    je      .noLeftChild            # yes
# On fall thru, there is a left child.
    cmpq    $NULL, right(%rbx)      # is currNode->right == NULL?
    jne     .twoChildren            # currNode->left != NULL && currNode->right != NULL
    jmp     .noRightChild

# case 2: no left child
.noLeftChild:
    movq    right(%rbx), %r13       # newNode = currNode->right
    jmp     .isParentNull

# case 3: no right child
.noRightChild:
    movq    left(%rbx), %r13       # newNode = currNode->left

.isParentNull:
# Check if the node to be deleted is the root of the tree.
    cmpq    $NULL, %r12             # is parentNode == NULL?
    jne     2f
    movq    %rbx, %rdi              # yes
    call    _free
    movq    %r13, (%rbp)            # *root = newNode
    jmp     .exitDelete

2:
    cmpq    left(%r12), %rbx        # is curr == parentNode->left?
    jne     3f
    movq    %r13, left(%r12)        # parentNode->left = newNode
    jmp     .freeNode

3:
    movq    %r13, right(%r12)       # parentNode->right = newNode

.freeNode:
    movq    %rbx, %rdi
    callq   _free
    jmp     .exitDelete

# case 4: Two children
.twoChildren:
    movq    $NULL, %r14             # successorParent = NULL;
    movq    right(%rbx), %r15       # successor = currNode->right;
#problem
.innerWhile:
    cmpq    $NULL, left(%r15)       # is successor->left == NULL?
    je      .exitInnerWhile
    movq    %r15, %r14              # successorParent = successor
    movq    left(%r15), %r15        # successor = successor->left
    jmp     .innerWhile

.exitInnerWhile:
    cmpq    $NULL, %r14             # is successorParent == NULL?
    je      1f
    movq    right(%r15), %rcx       # successorParent->left = successor->right
    movq    %rcx, left(%r14)
    jmp     2f

# Special case: main root node is deleted; this is the only node that does not
# have a parent node.
1:
    movq    right(%r15), %rcx
    movq    %rcx, right(%rbx)       # currNode->right = successor->right

2:
    movq    key(%r15), %rdx
    movq    %rdx, key(%rbx)         # currNode->key = successor->key
    movq    %r15, %rdi
    callq   _free

.exitDelete:
    movq    (%rsp), %rbp
    movq    8(%rsp), %rbx
    movq    16(%rsp), %r12
    movq    24(%rsp), %r13
    movq    32(%rsp), %r14
    movq    40(%rsp), %r15
    addq    $48+8, %rsp
    ret
