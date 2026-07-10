document.addEventListener('DOMContentLoaded', () => {
  // Select Hugo's highlight wrapper or fallback to standard pre
  const blocks = document.querySelectorAll('.highlight, pre:not(.highlight pre)');

  blocks.forEach((block) => {
    if (block.querySelector('.copy-btn')) return;

    const button = document.createElement('button');
    button.className = 'copy-btn';
    button.innerText = 'Copy';

    button.addEventListener('click', () => {
      let textToCopy = '';
      
      const lntable = block.querySelector('.lntable');
      if (lntable) {
        // In line-numbered code, the actual code is in the last column
        const codeTd = lntable.querySelector('.lntd:last-child');
        textToCopy = codeTd ? codeTd.innerText : '';
      } else {
        const code = block.querySelector('code');
        textToCopy = code ? code.innerText : block.innerText;
      }

      navigator.clipboard.writeText(textToCopy).then(() => {
        button.innerText = 'Copied!';
        button.classList.add('copied');
        setTimeout(() => {
          button.innerText = 'Copy';
          button.classList.remove('copied');
        }, 2000);
      }).catch(err => {
        console.error('Failed to copy: ', err);
      });
    });

    block.style.position = 'relative';
    block.appendChild(button);
  });
});
